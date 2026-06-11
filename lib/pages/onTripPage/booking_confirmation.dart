import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:lottie/lottie.dart' as lottile;
import 'package:vector_math/vector_math.dart' as vector;
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:share_plus/share_plus.dart';
import '../../functions/functions.dart';
import '../../functions/geohash.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../chatPage/chat_page.dart';
import '../in_app_calling/call_screen.dart';
import '../in_app_calling/incomming_call_screen.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import 'choosegoods.dart';
import 'drop_loc_select.dart';
import 'invoice.dart';
import 'map_page.dart';

class BookingConfirmation extends StatefulWidget {
  dynamic type;

  //type = 1 is rental ride and type = null is regular ride
  BookingConfirmation({Key? key, this.type}) : super(key: key);

  @override
  State<BookingConfirmation> createState() => _BookingConfirmationState();
}

// Calling constants

const callingStatus = 'calling_status';
const shouldShowIncommingCall = 'should_show_incomming_call';
const callingStatusIncomming = 'incomming';
const readyForCall = 'ready';
const callingStatusDeclined = 'declined';
Map rideRequest = {};

bool serviceNotAvailable = false;
String promoCode = '';
dynamic promoStatus;
dynamic choosenVehicle;
int payingVia = 0;
dynamic timing;
dynamic mapPadding = 0.0;
String goodsSize = '';
bool noDriverFound = false;
var driverData = {};
var driversData = [];
dynamic choosenDateTime;
bool lowWalletBalance = false;
bool tripReqError = false;
List rentalOption = [];
int rentalChoosenOption = 0;
Animation<double>? _animation;
Set<Polyline> sourceToDestPolylines = {};

class _BookingConfirmationState extends State<BookingConfirmation>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  Stream<DatabaseEvent>? _driverStream;
  String? _lastDriverId;
  TextEditingController promoKey = TextEditingController();
  final Map minutes = {};
  List myMarker = [];
  Map myBearings = {};
  String _cancelReason = '';
  dynamic _controller;
  late PermissionStatus permission;
  bool _addCoupon = false;
  bool bottomChooseMethod = false;
  bool islowwalletbalance = false;
  List gesture = [];
  dynamic start;

  Location location = Location();
  bool _locationDenied = false;
  bool _isLoading = false;
  LatLng _center = const LatLng(41.4219057, -102.0840772);
  dynamic pinLocationIcon;
  dynamic pinLocationIcon2;
  dynamic animationController;
  bool _ontripBottom = false;
  bool _cancelling = false;
  bool _choosePayment = false;
  String _cancelCustomReason = '';
  dynamic timers;
  bool _dateTimePicker = false;
  bool _rideLaterSuccess = false;
  bool _confirmRideLater = false;
  bool showSos = false;
  bool notifyCompleted = false;
  bool _showInfo = false;
  bool _showChoosePaymentMethodSheet = false;
  dynamic _showInfoInt;
  dynamic _dist;
  String _cancellingError = '';
  GlobalKey iconKey = GlobalKey();
  GlobalKey iconDropKey = GlobalKey();
  GlobalKey iconDistanceKey = GlobalKey();
  var iconDropKeys = {};
  List driverBck = [];
  bool currentpage = true;
  final _mapMarkerSC = StreamController<List<Marker>>();
  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
  Stream<List<Marker>> get mapMarkerStream => _mapMarkerSC.stream;
  bool dropConfirmed = false;
  void _updateDriverStream(String lower, String higher) {
    if (_lastDriverId == '$lower$higher') return;
    _lastDriverId = '$lower$higher';
    _driverStream = FirebaseDatabase.instance
        .ref('drivers')
        .orderByChild('g')
        .startAt(lower)
        .endAt(higher)
        .onValue
        .asBroadcastStream();
  }
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    promoCode = '';
    mapPadding = 0.0;
    promoStatus = null;
    serviceNotAvailable = false;
    tripReqError = false;
    myBearings.clear();
    noDriverFound = false;
    etaDetails.clear();
    currentpage = true;
    selectedGoodsId = '';
    if (widget.type == 1 || widget.type == 2) {
      setState(() {
        dropConfirmed = true;
      });
    }
    getLocs();
    FirebaseDatabase.instance
        .ref('requests/${userRequestData['id']}')
        .onValue
        .listen((event) async {
      if (event.snapshot.value == null) return;
      rideRequest = event.snapshot.value as Map;
      String currentCallingStatus = rideRequest[callingStatus]?.toString() ?? '';
      bool shouldShowIncommingCallScreen = rideRequest[shouldShowIncommingCall] == true;
      bool isDriverCalling = rideRequest['driver'] == true;

      if (isDriverCalling == true &&
          currentCallingStatus == callingStatusIncomming &&
          shouldShowIncommingCallScreen) {
        FlutterRingtonePlayer().playRingtone(volume: 1.0);
        await Navigator.of(context).push(CupertinoPageRoute(
          builder: (context) {
            return IncommingCallScreen();
          },
        ));
      }
    });
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
      }
      getUserDetails();
      if (timers == null &&
          userRequestData.isNotEmpty &&
          userRequestData['accepted_at'] == null) {
        timer();
      }
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
    }
  }

  @override
  void dispose() {
    if (timers != null) {
      timers?.cancel;
    }

    _controller?.dispose();
    _controller = null;
    animationController?.dispose();
    _driverStream = null;
    super.dispose();
  }

//running timer
  timer() {
    timing = userRequestData['maximum_time_for_find_drivers_for_regular_ride'];

    if (mounted) {
      timers = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (timing != null) {
          if (userRequestData.isNotEmpty &&
              userDetails['accepted_at'] == null &&
              timing > 0) {
            timing--;
            valueNotifierBook.incrementNotifier();
          } else if (userRequestData.isNotEmpty &&
              userRequestData['accepted_at'] == null &&
              timing == 0) {
            var val = await cancelRequest();
            if (mounted) {
              setState(() {
                noDriverFound = true;
              });
            }
            timer.cancel();
            timing = null;
            if (val == 'logout') {
              navigateLogout();
            }
          } else {
            timer.cancel();
            timing = null;
          }
        } else {
          timer.cancel();
          timing = null;
        }
      });
    }
  }

//create icon

  _capturePng(GlobalKey iconKeys) async {
    dynamic bitmap;

    try {
      RenderRepaintBoundary boundary =
          iconKeys.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();
      bitmap = BitmapDescriptor.fromBytes(pngBytes);
      // return pngBytes;
    } catch (e) {
      debugPrint(e.toString());
    }
    return bitmap;
  }

  addDropMarker() async {
    for (var i = 1; i < addressList.length; i++) {
      var testIcon = await _capturePng(iconDropKeys[i]);
      if (testIcon != null) {
        setState(() {
          myMarker.add(Marker(
              markerId: MarkerId((i + 1).toString()),
              icon: testIcon,
              position: addressList[i].latlng));
        });
      }
    }

    if (widget.type != 1) {
      LatLngBounds bound;
      if (userRequestData.isNotEmpty) {
        if (userRequestData['pick_lat'] > userRequestData['drop_lat'] &&
            userRequestData['pick_lng'] > userRequestData['drop_lng']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']),
              northeast: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng']));
        } else if (userRequestData['pick_lng'] > userRequestData['drop_lng']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['pick_lat'], userRequestData['drop_lng']),
              northeast: LatLng(
                  userRequestData['drop_lat'], userRequestData['pick_lng']));
        } else if (userRequestData['pick_lat'] > userRequestData['drop_lat']) {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['drop_lat'], userRequestData['pick_lng']),
              northeast: LatLng(
                  userRequestData['pick_lat'], userRequestData['drop_lng']));
        } else {
          bound = LatLngBounds(
              southwest: LatLng(
                  userRequestData['pick_lat'], userRequestData['pick_lng']),
              northeast: LatLng(
                  userRequestData['drop_lat'], userRequestData['drop_lng']));
        }
      } else {
        if (addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                    .latitude >
                addressList
                    .lastWhere((element) => element.type == 'drop')
                    .latlng
                    .latitude &&
            addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                    .longitude >
                addressList
                    .lastWhere((element) => element.type == 'drop')
                    .latlng
                    .longitude) {
          bound = LatLngBounds(
              southwest: addressList
                  .lastWhere((element) => element.type == 'drop')
                  .latlng,
              northeast: addressList
                  .firstWhere((element) => element.type == 'pickup')
                  .latlng);
        } else if (addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .longitude) {
          bound = LatLngBounds(
              southwest: LatLng(
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .latitude,
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .longitude),
              northeast: LatLng(
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .latitude,
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .longitude));
        } else if (addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude >
            addressList
                .lastWhere((element) => element.type == 'drop')
                .latlng
                .latitude) {
          bound = LatLngBounds(
              southwest: LatLng(
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .latitude,
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .longitude),
              northeast: LatLng(
                  addressList
                      .firstWhere((element) => element.type == 'pickup')
                      .latlng
                      .latitude,
                  addressList
                      .lastWhere((element) => element.type == 'drop')
                      .latlng
                      .longitude));
        } else {
          bound = LatLngBounds(
              southwest: addressList
                  .firstWhere((element) => element.type == 'pickup')
                  .latlng,
              northeast: addressList
                  .lastWhere((element) => element.type == 'drop')
                  .latlng);
        }
      }
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bound, 50);
      _controller!.animateCamera(cameraUpdate);
      // CameraUpdate.newCameraPosition(CameraPosition(target: target))
    }
  }

  Future<void> addMarker() async {
    var testIcon = await _capturePng(iconKey);

    // if (destinationLocation != null) {
    //   drawPolylineBetweenPoints(
    //       (userRequestData.isEmpty)
    //           ? addressList
    //               .firstWhere((element) => element.type == 'pickup')
    //               .latlng
    //           : LatLng(
    //               userRequestData['pick_lat'], userRequestData['pick_lng']),
    //       destinationLocation!);
    // }

    if (testIcon != null) {
      setState(() {
        myMarker.add(Marker(
            markerId: const MarkerId('1'),
            icon: testIcon,
            position: (userRequestData.isEmpty)
                ? addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
                : LatLng(
                    userRequestData['pick_lat'], userRequestData['pick_lng'])));
        // if (destinationLocation != null) {
        //   myMarker.add(Marker(
        //       markerId: MarkerId('Destination Location Marker'),
        //       position: destinationLocation!));
        // }
      });
    }
  }

//add distance marker
  addDistanceMarker(length) async {
    var testIcon = await _capturePng(iconDistanceKey);
    if (testIcon != null) {
      setState(() {
        if (polyList.isNotEmpty) {
          myMarker.add(Marker(
              markerId: const MarkerId('pointdistance'),
              icon: testIcon,
              position: polyList[length],
              anchor: const Offset(0.0, 1.0)));
        }
      });
    }
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

//add drop marker
  addPickDropMarker() async {
    await addMarker();
    // Future.delayed(const Duration(milliseconds: 200), () async {
    if (userRequestData.isNotEmpty &&
        userRequestData['is_rental'] != true &&
        userRequestData['drop_address'] != null) {
      addDropMarker();
      if (userRequestData.isEmpty) {
        polyline.add(
          Polyline(
              polylineId: const PolylineId('1'),
              color: buttonColor,
              points: [
                addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng,
                addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
              ],
              geodesic: false,
              width: 5),
        );
      } else {
        polyline.add(
          Polyline(
              polylineId: const PolylineId('1'),
              color: buttonColor,
              points: [
                LatLng(double.parse(userRequestData['pick_lat'].toString()),
                    double.parse(userRequestData['pick_lng'].toString())),
                LatLng(double.parse(userRequestData['pick_lat'].toString()),
                    double.parse(userRequestData['pick_lng'].toString()))
              ],
              geodesic: false,
              width: 5),
        );
      }

      getPolylines();
    } else if (widget.type == null) {
      addDropMarker();
      if (userRequestData.isEmpty) {
        polyline.add(
          Polyline(
              polylineId: const PolylineId('1'),
              color: buttonColor,
              points: [
                addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng,
                addressList
                    .firstWhere((element) => element.type == 'pickup')
                    .latlng
              ],
              geodesic: false,
              width: 5),
        );
      } else {
        polyline.add(
          Polyline(
              polylineId: const PolylineId('1'),
              color: buttonColor,
              points: [
                LatLng(double.parse(userRequestData['pick_lat'].toString()),
                    double.parse(userRequestData['pick_lng'].toString())),
                LatLng(double.parse(userRequestData['pick_lat'].toString()),
                    double.parse(userRequestData['pick_lng'].toString()))
              ],
              geodesic: false,
              width: 5),
        );
      }

      await getPolylines();
    } else {
      if (userRequestData.isNotEmpty) {
        CameraUpdate cameraUpdate = CameraUpdate.newLatLng(
            LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']));
        _controller!.animateCamera(cameraUpdate);
      } else {
        CameraUpdate cameraUpdate = CameraUpdate.newLatLng(addressList
            .firstWhere((element) => element.type == 'pickup')
            .latlng);
        _controller!.animateCamera(cameraUpdate);
      }
    }
  }

  Future<Uint8List> getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

//get location permission and location details
  getLocs() async {
    setState(() {
      _center = (userRequestData.isEmpty)
          ? addressList.firstWhere((element) => element.type == 'pickup').latlng
          : LatLng(userRequestData['pick_lat'], userRequestData['pick_lng']);
    });
    if (await geolocs.GeolocatorPlatform.instance.isLocationServiceEnabled()) {
      serviceEnabled = true;
    } else {
      serviceEnabled = false;
    }
    final Uint8List markerIcon;
    final Uint8List markerIcon2;
    markerIcon = await getBytesFromAsset('assets/images/top-taxi.png', 60);
    pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
    markerIcon2 = await getBytesFromAsset('assets/images/bike.png', 40);
    pinLocationIcon2 = BitmapDescriptor.fromBytes(markerIcon2);

    choosenVehicle = null;
    _dist = null;

    if (widget.type == 2) {
      var val = await etaRequest();
      if (val == 'logout') {
        navigateLogout();
      }
    }
    if (widget.type == 1) {
      var val = await rentalEta();
      if (val == 'logout') {
        navigateLogout();
      }
    }

    permission = await location.hasPermission();

    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever) {
      setState(() {
        locationAllowed = false;
      });
    } else if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
      setState(() {});
    }
    Future.delayed(const Duration(milliseconds: 100), () async {
      await addPickDropMarker();
    });
  }

  void _onMapCreated(GoogleMapController controller) async {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    c.animateCamera(u);
    _controller!.animateCamera(u);
    LatLngBounds l1 = await c.getVisibleRegion();
    LatLngBounds l2 = await c.getVisibleRegion();
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      check(u, c);
    }
  }

  popFunction() {
    if (userRequestData.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    etaDetails.toList().forEach((element) {
      print(
          'this is my ride fare ${element['ride_fare']}  and distance ${element['distance']}');
    });
    GeoHasher geo = GeoHasher();
    double lat = 0.0144927536231884;
    double lon = 0.0181818181818182;
    double lowerLat = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude -
            (lat * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lat'] - (lat * 1.24)
            : 0.0;
    double lowerLon = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude -
            (lon * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lng'] - (lon * 1.24)
            : 0.0;

    double greaterLat = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .latitude +
            (lat * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lat'] - (lat * 1.24)
            : 0.0;
    double greaterLon = (userRequestData.isEmpty && addressList.isNotEmpty)
        ? addressList
                .firstWhere((element) => element.type == 'pickup')
                .latlng
                .longitude +
            (lon * 1.24)
        : (userRequestData.isNotEmpty && addressList.isEmpty)
            ? userRequestData['pick_lng'] - (lat * 1.24)
            : 0.0;
    var lower = geo.encode(lowerLon, lowerLat);
    var higher = geo.encode(greaterLon, greaterLat);

    var fdb = FirebaseDatabase.instance
        .ref('drivers')
        .orderByChild('g')
        .startAt(lower)
        .endAt(higher);

    var media = MediaQuery.of(context).size;
    return WillPopScope(
      onWillPop: () {
        if (userRequestData.isEmpty) {
          if (widget.type == null) {
            if (dropConfirmed) {
              setState(() {
                dropConfirmed = false;
              });
            } else {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const Maps()),
                  (route) => false);
              addressList.removeWhere((element) => element.id == 'drop');
              etaDetails.clear();
              promoKey.clear();
              promoStatus = null;
              rentalOption.clear();
              _rideLaterSuccess = false;
              myMarker.clear();
              dropStopList.clear();
            }
          } else {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Maps()),
                (route) => false);
            addressList.removeWhere((element) => element.id == 'drop');
            etaDetails.clear();
            promoKey.clear();
            promoStatus = null;
            rentalOption.clear();
            _rideLaterSuccess = false;
            myMarker.clear();
            dropStopList.clear();
          }
        }
        return popFunction();
      },
      child: Material(
        child: Directionality(
          textDirection: (languageDirection == 'rtl')
              ? ui.TextDirection.rtl
              : ui.TextDirection.ltr,
          child: Container(
            height: media.height * 1,
            width: media.width * 1,
            color: page,
            child: ValueListenableBuilder(
                valueListenable: valueNotifierBook.value,
                builder: (context, value, child) {
                  if (_controller != null) {
                    mapPadding = media.width * 1;
                  }
                  if (cancelRequestByUser == true) {
                    myMarker.clear();
                    polyline.clear();
                    addressList
                        .removeWhere((element) => element.type == 'drop');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const Maps()),
                          (route) => false);
                    });
                  }
                  if (userRequestData['is_completed'] == 1 &&
                      currentpage == true) {
                    currentpage = false;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Invoice()),
                          (route) => false);
                    });
                  }
                  if (userRequestData.isNotEmpty &&
                      timing == null &&
                      userRequestData['accepted_at'] == null) {
                    timer();
                  } else if (userRequestData.isNotEmpty &&
                      userRequestData['accepted_at'] != null) {
                    timing = null;
                  }
                  if (userRequestData.isNotEmpty &&
                      userRequestData['accepted_at'] != null) {
                    if (myMarker
                        .where((element) =>
                            element.markerId == const MarkerId('pointdistance'))
                        .isNotEmpty) {
                      myMarker.removeWhere((element) =>
                          element.markerId == const MarkerId('pointdistance'));
                    }
                  }
                  return StreamBuilder<DatabaseEvent>(
                      stream: (userRequestData['driverDetail'] == null &&
                          pinLocationIcon != null)
                          ? _driverStream
                          : null,
                      builder: (context, AsyncSnapshot<DatabaseEvent> event) {
                        if (event.hasData) {
                          if (event.data!.snapshot.value != null) {
                            if (userRequestData['accepted_at'] == null) {
                              DataSnapshot snapshots = event.data!.snapshot;
                              // ignore: unnecessary_null_comparison
                              if (snapshots != null &&
                                  choosenVehicle != null &&
                                  etaDetails.isNotEmpty) {
                                driversData = [];
                                // ignore: avoid_function_literals_in_foreach_calls
                                snapshots.children.forEach((element) {
                                  driversData.add(element.value);
                                });
                                // ignore: avoid_function_literals_in_foreach_calls
                                driversData.forEach((e) {
                                  if (e['is_active'] == 1 &&
                                      e['is_available'] == true) {
                                    if (((e['vehicle_types'] != null &&
                                            ((widget.type != 1 &&
                                                    e['vehicle_types'].contains(
                                                        etaDetails[choosenVehicle]
                                                            ['type_id'])) ||
                                                (widget.type == 1 &&
                                                    e['vehicle_types'].contains(
                                                        rentalOption[choosenVehicle]
                                                            ['type_id'])))) ||
                                        ((widget.type != 1 &&
                                                e['vehicle_type'] ==
                                                    etaDetails[choosenVehicle]
                                                        ['type_id']) ||
                                            (widget.type == 1 &&
                                                e['vehicle_type'] ==
                                                    rentalOption[choosenVehicle]
                                                        ['type_id'])))) {
                                      DateTime dt =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              e['updated_at']);
                                      if (DateTime.now()
                                              .difference(dt)
                                              .inMinutes <=
                                          2) {
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains('car${e['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId('car${e['id']}'),
                                            rotation: (myBearings[
                                                        e['id'].toString()] !=
                                                    null)
                                                ? myBearings[e['id'].toString()]
                                                : 0.0,
                                            position:
                                                LatLng(e['l'][0], e['l'][1]),
                                            icon: (e['vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                              'car${e['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                              'car${e['id']}'))
                                                  .position
                                                  .longitude,
                                              e['l'][0],
                                              e['l'][1]);
                                          if (dist > 10) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car${e['id']}'))
                                                        .position
                                                        .latitude !=
                                                    e['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car${e['id']}'))
                                                            .position
                                                            .longitude !=
                                                        e['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );
                                              animateCar(
                                                myMarker
                                                    .lastWhere((element) =>
                                                        element.markerId
                                                            .toString()
                                                            .contains(
                                                                'car${e['id']}'))
                                                    .position
                                                    .latitude,
                                                myMarker
                                                    .lastWhere((element) =>
                                                        element.markerId
                                                            .toString()
                                                            .contains(
                                                                'car${e['id']}'))
                                                    .position
                                                    .longitude,
                                                e['l'][0],
                                                e['l'][1],
                                                _mapMarkerSink,
                                                this,
                                                _controller,
                                                'car${e['id']}',
                                                e['id'],
                                                (e['vehicle_type_icon'] ==
                                                        'motor_bike')
                                                    ? pinLocationIcon2
                                                    : pinLocationIcon,
                                              );
                                            }
                                          }
                                        }
                                      }
                                    } else if (((e['vehicle_types'] != null &&
                                            ((widget.type != 1 &&
                                                    e['vehicle_types'].contains(
                                                        etaDetails[choosenVehicle]
                                                            ['type_id'])) ||
                                                (widget.type == 1 &&
                                                    e['vehicle_types'].contains(
                                                        rentalOption[choosenVehicle]
                                                            ['type_id'])))) ||
                                        ((widget.type != 1 &&
                                                e['vehicle_type'] ==
                                                    etaDetails[choosenVehicle]
                                                        ['type_id']) ||
                                            (widget.type == 1 &&
                                                e['vehicle_type'] ==
                                                    rentalOption[choosenVehicle]
                                                        ['type_id'])))) {
                                      DateTime dt =
                                          DateTime.fromMillisecondsSinceEpoch(
                                              e['updated_at']);
                                      if (DateTime.now()
                                              .difference(dt)
                                              .inMinutes <=
                                          2) {
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains('car${e['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId('car${e['id']}'),
                                            rotation: (myBearings[
                                                        e['id'].toString()] !=
                                                    null)
                                                ? myBearings[e['id'].toString()]
                                                : 0.0,
                                            position:
                                                LatLng(e['l'][0], e['l'][1]),
                                            icon: (e['vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                              'car${e['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) =>
                                                      element.markerId
                                                          .toString()
                                                          .contains(
                                                              'car${e['id']}'))
                                                  .position
                                                  .longitude,
                                              e['l'][0],
                                              e['l'][1]);
                                          if (dist > 10) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car${e['id']}'))
                                                        .position
                                                        .latitude !=
                                                    e['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car${e['id']}'))
                                                            .position
                                                            .longitude !=
                                                        e['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );
                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${e['id']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${e['id']}'))
                                                      .position
                                                      .longitude,
                                                  e['l'][0],
                                                  e['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  _controller,
                                                  'car${e['id']}',
                                                  e['id'],
                                                  (driverData['vehicle_type_icon'] ==
                                                          'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    } else {
                                      if (myMarker
                                          .where((element) => element.markerId
                                              .toString()
                                              .contains('car${e['id']}'))
                                          .isNotEmpty) {
                                        myMarker.removeWhere((element) =>
                                            element.markerId
                                                .toString()
                                                .contains('car${e['id']}'));
                                      } else {
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains('car${e['id']}'))
                                            .isNotEmpty) {
                                          myMarker.removeWhere((element) =>
                                              element.markerId
                                                  .toString()
                                                  .contains('car${e['id']}'));
                                        }
                                      }
                                    }
                                  }
                                });
                              }
                            }
                          }
                        }
                        return StreamBuilder<DatabaseEvent>(
                            stream: (userRequestData['driverDetail'] != null &&
                                    pinLocationIcon != null)
                                ? FirebaseDatabase.instance
                                    .ref(
                                        'drivers/driver_${userRequestData['driverDetail']['data']['id']}')
                                    .onValue
                                    .asBroadcastStream()
                                : null,
                            builder:
                                (context, AsyncSnapshot<DatabaseEvent> event) {
                              if (event.hasData) {
                                if (event.data!.snapshot.value != null) {
                                  if (userRequestData['accepted_at'] != null) {
                                    driversData.clear();
                                    if (myMarker.length > 3) {
                                      myMarker.removeWhere((element) => element
                                          .markerId
                                          .toString()
                                          .contains('car'));
                                    }

                                    DataSnapshot snapshots =
                                        event.data!.snapshot;
                                    // ignore: unnecessary_null_comparison
                                    if (snapshots != null) {
                                      driverData = jsonDecode(
                                          jsonEncode(snapshots.value));
                                      if (userRequestData != {}) {
                                        if (userRequestData['arrived_at'] ==
                                            null) {
                                          var distCalc = calculateDistance(
                                              userRequestData['pick_lat'],
                                              userRequestData['pick_lng'],
                                              driverData['l'][0],
                                              driverData['l'][1]);
                                          _dist = double.parse(
                                              (distCalc / 1000).toString());
                                        } else if (userRequestData[
                                                    'is_rental'] !=
                                                true &&
                                            userRequestData['drop_lat'] !=
                                                null) {
                                          var distCalc = calculateDistance(
                                            driverData['l'][0],
                                            driverData['l'][1],
                                            userRequestData['drop_lat'],
                                            userRequestData['drop_lng'],
                                          );
                                          _dist = double.parse(
                                              (distCalc / 1000).toString());
                                        }
                                        if (myMarker
                                            .where((element) => element.markerId
                                                .toString()
                                                .contains(
                                                    'car${driverData['id']}'))
                                            .isEmpty) {
                                          myMarker.add(Marker(
                                            markerId: MarkerId(
                                                'car${driverData['id']}'),
                                            rotation: (myBearings[
                                                        driverData['id']
                                                            .toString()] !=
                                                    null)
                                                ? myBearings[
                                                    driverData['id'].toString()]
                                                : 0.0,
                                            position: LatLng(driverData['l'][0],
                                                driverData['l'][1]),
                                            icon: (driverData[
                                                        'vehicle_type_icon'] ==
                                                    'motor_bike')
                                                ? pinLocationIcon2
                                                : pinLocationIcon,
                                          ));
                                        } else if (_controller != null) {
                                          var dist = calculateDistance(
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car${driverData['id']}'))
                                                  .position
                                                  .latitude,
                                              myMarker
                                                  .lastWhere((element) => element
                                                      .markerId
                                                      .toString()
                                                      .contains(
                                                          'car${driverData['id']}'))
                                                  .position
                                                  .longitude,
                                              driverData['l'][0],
                                              driverData['l'][1]);
                                          if (dist > 10) {
                                            if (myMarker
                                                        .lastWhere((element) =>
                                                            element.markerId
                                                                .toString()
                                                                .contains(
                                                                    'car${driverData['id']}'))
                                                        .position
                                                        .latitude !=
                                                    driverData['l'][0] ||
                                                myMarker
                                                            .lastWhere((element) =>
                                                                element.markerId
                                                                    .toString()
                                                                    .contains(
                                                                        'car${driverData['id']}'))
                                                            .position
                                                            .longitude !=
                                                        driverData['l'][1] &&
                                                    _controller != null) {
                                              animationController =
                                                  AnimationController(
                                                duration: const Duration(
                                                    milliseconds:
                                                        1500), //Animation duration of marker

                                                vsync: this, //From the widget
                                              );

                                              animateCar(
                                                  myMarker
                                                      .lastWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${driverData['id']}'))
                                                      .position
                                                      .latitude,
                                                  myMarker
                                                      .firstWhere((element) =>
                                                          element.markerId
                                                              .toString()
                                                              .contains(
                                                                  'car${driverData['id']}'))
                                                      .position
                                                      .longitude,
                                                  driverData['l'][0],
                                                  driverData['l'][1],
                                                  _mapMarkerSink,
                                                  this,
                                                  _controller,
                                                  'car${driverData['id']}',
                                                  driverData['id'],
                                                  (driverData['vehicle_type_icon'] ==
                                                          'motor_bike')
                                                      ? pinLocationIcon2
                                                      : pinLocationIcon);
                                            }
                                          }
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      //get drivers location updates
                                      child: StreamBuilder<List<Marker>>(
                                          stream: mapMarkerStream,
                                          builder: (context, snapshot) {
                                            return GoogleMap(
                                              padding: EdgeInsets.only(
                                                  bottom: mapPadding,
                                                  top: media.height * 0.1 +
                                                      MediaQuery.of(context)
                                                          .padding
                                                          .top),
                                              onMapCreated: _onMapCreated,
                                              compassEnabled: false,
                                              initialCameraPosition:
                                                  CameraPosition(
                                                target: _center,
                                                zoom: 11.0,
                                              ),
                                              markers:
                                                  Set<Marker>.from(myMarker),
                                              polylines: {
                                                ...polyline,
                                                ...sourceToDestPolylines
                                              },
                                              minMaxZoomPreference:
                                                  const MinMaxZoomPreference(
                                                      0.0, 20.0),
                                              myLocationButtonEnabled: false,
                                              buildingsEnabled: false,
                                              zoomControlsEnabled: false,
                                              myLocationEnabled: true,
                                            );
                                          })),
                                  (userRequestData.isEmpty)
                                      ? Positioned(
                                          top: MediaQuery.of(context)
                                                  .padding
                                                  .top +
                                              12.5,
                                          child: SizedBox(
                                            width: media.width * 0.9,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                InkWell(
                                                    onTap: () {
                                                      if (widget.type == null) {
                                                        if (dropConfirmed) {
                                                          setState(() {
                                                            dropConfirmed =
                                                                false;
                                                          });
                                                        } else {
                                                          addressList
                                                              .removeWhere(
                                                                  (element) =>
                                                                      element
                                                                          .id ==
                                                                      'drop');
                                                          etaDetails.clear();
                                                          promoKey.clear();
                                                          promoStatus = null;
                                                          rentalOption.clear();
                                                          _rideLaterSuccess =
                                                              false;
                                                          myMarker.clear();
                                                          dropStopList.clear();
                                                          Navigator.pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          const Maps()),
                                                              (route) => false);
                                                        }
                                                      } else {
                                                        addressList.removeWhere(
                                                            (element) =>
                                                                element.id ==
                                                                'drop');
                                                        etaDetails.clear();
                                                        promoKey.clear();
                                                        promoStatus = null;
                                                        rentalOption.clear();
                                                        _rideLaterSuccess =
                                                            false;
                                                        myMarker.clear();
                                                        dropStopList.clear();
                                                        Navigator.pushAndRemoveUntil(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const Maps()),
                                                            (route) => false);
                                                      }
                                                    },
                                                    child: IosBackButton(
                                                      width: Responsive.width(
                                                          9.5, context),
                                                      height: Responsive.width(
                                                          9.5, context),
                                                    )),
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(),
                                  Positioned(
                                    bottom: media.width * 1.15,
                                    // top: media.width*0.2 + MediaQuery.of(context).padding.top,
                                    child: SizedBox(
                                      width: media.width * 0.9,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          if (userRequestData.isNotEmpty &&
                                              userRequestData['accepted_at'] !=
                                                  null)
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                InkWell(
                                                  onTap: () async {
                                                    await Share.share(
                                                        'My Driver is ${userRequestData['driverDetail']['data']['name']}. ${userRequestData['driverDetail']['data']['car_make_name']} ${userRequestData['driverDetail']['data']['car_model_name']}, Vehicle Number: ${userRequestData['driverDetail']['data']['car_number']}. Track with link: ${url}track/request/${userRequestData['id']}');
                                                  },
                                                  child: Container(
                                                      height: media.width * 0.1,
                                                      width: media.width * 0.1,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: white),
                                                      alignment:
                                                          Alignment.center,
                                                      child: Icon(
                                                        Icons.share_outlined,
                                                        color: black,
                                                      )),
                                                ),
                                              ],
                                            ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          (userRequestData.isNotEmpty &&
                                                  userRequestData[
                                                          'is_trip_start'] ==
                                                      1)
                                              ? InkWell(
                                                  onTap: () async {
                                                    setState(() {
                                                      showSos = true;
                                                    });
                                                  },
                                                  child: Container(
                                                    height: media.width * 0.11,
                                                    width: media.width * 0.11,
                                                    decoration: BoxDecoration(
                                                        color: buttonColor,
                                                        shape: BoxShape.circle),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      'SOS',
                                                      style: GoogleFonts.inter(
                                                          fontSize:
                                                              media.width *
                                                                  fourteen,
                                                          color: textColor),
                                                    ),
                                                  ))
                                              : Container(),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          (etaDetails.isNotEmpty ||
                                                  userRequestData.isNotEmpty)
                                              ? InkWell(
                                                  onTap: () async {
                                                    if (locationAllowed ==
                                                        true) {
                                                      if (currentLocation !=
                                                          null) {
                                                        _controller?.animateCamera(
                                                            CameraUpdate
                                                                .newLatLngZoom(
                                                                    currentLocation,
                                                                    18.0));
                                                        center =
                                                            currentLocation;
                                                      } else {
                                                        _controller?.animateCamera(
                                                            CameraUpdate
                                                                .newLatLngZoom(
                                                                    center,
                                                                    18.0));
                                                      }
                                                    } else {
                                                      if (serviceEnabled ==
                                                          true) {
                                                        setState(() {
                                                          _locationDenied =
                                                              true;
                                                        });
                                                      } else {
                                                        await geolocs.Geolocator
                                                            .getCurrentPosition(
                                                                desiredAccuracy:
                                                                    geolocs
                                                                        .LocationAccuracy
                                                                        .low);
                                                        if (await geolocs
                                                            .GeolocatorPlatform
                                                            .instance
                                                            .isLocationServiceEnabled()) {
                                                          setState(() {
                                                            _locationDenied =
                                                                true;
                                                          });
                                                        }
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    height: media.width * 0.1,
                                                    width: media.width * 0.1,
                                                    decoration: BoxDecoration(
                                                        boxShadow: [
                                                          BoxShadow(
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2),
                                                          )
                                                        ],
                                                        color: white,
                                                        shape: BoxShape.circle),
                                                    child: Icon(
                                                      Icons.near_me_outlined,
                                                      color: black,
                                                    ),
                                                  ),
                                                )
                                              : Container(),
                                        ],
                                      ),
                                    ),
                                  ),

                                  //show bottom nav bar for choosing ride type and vehicles
                                  (_isLoading == false &&
                                          addressList.isNotEmpty &&
                                          etaDetails.isNotEmpty &&
                                          userRequestData.isEmpty &&
                                          noDriverFound == false &&
                                          tripReqError == false &&
                                          dropConfirmed == true &&
                                          lowWalletBalance == false)
                                      ? Positioned(
                                          bottom: 0 +
                                              MediaQuery.of(context)
                                                  .viewInsets
                                                  .bottom,
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            padding: EdgeInsets.only(
                                                left: Responsive.width(
                                                    3, context),
                                                right: Responsive.width(
                                                    3, context),
                                                top: media.width * 0.02,
                                                bottom: media.width * 0.02),
                                            width: media.width * 1,
                                            height:
                                                (bottomChooseMethod == false &&
                                                        widget.type != 1)
                                                    ? null
                                                    : (bottomChooseMethod ==
                                                                false &&
                                                            widget.type == 1)
                                                        ? media.height * 0.6
                                                        : media.height * 0.9,
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(25),
                                                        topRight:
                                                            Radius.circular(
                                                                25)),
                                                color: darkModeDialogColor),
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      left: media.width * 0.05,
                                                      right:
                                                          media.width * 0.05),
                                                  width: media.width * 0.9,
                                                  child: MyText(
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_availablerides'],
                                                    size: 23,
                                                    fontweight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                (etaDetails.isNotEmpty &&
                                                        widget.type != 1)
                                                    ? SizedBox(
                                                        width: media.width * 1,
                                                        // height:
                                                        //     media.height *
                                                        //         0.6,
                                                        child: Column(
                                                          children: etaDetails
                                                              .asMap()
                                                              .map((i, value) {
                                                                return MapEntry(
                                                                    i,
                                                                    StreamBuilder<
                                                                            DatabaseEvent>(
                                                                        stream: fdb
                                                                            .onValue,
                                                                        builder:
                                                                            (context,
                                                                                AsyncSnapshot event) {
                                                                          if (event.data !=
                                                                              null) {
                                                                            minutes[etaDetails[i]['type_id']] =
                                                                                '';
                                                                            List
                                                                                vehicleList =
                                                                                [];
                                                                            List
                                                                                vehicles =
                                                                                [];
                                                                            List<double>
                                                                                minsList =
                                                                                [];
                                                                            event.data!.snapshot.children.forEach((e) {
                                                                              vehicleList.add(e.value);
                                                                            });
                                                                            if (vehicleList.isNotEmpty) {
                                                                              // ignore: avoid_function_literals_in_foreach_calls
                                                                              vehicleList.forEach(
                                                                                (e) async {
                                                                                  if (e['is_active'] == 1 && e['is_available'] == true && ((e['vehicle_types'] != null && e['vehicle_types'].contains(etaDetails[i]['type_id'])) || e['vehicle_type'] == etaDetails[i]['type_id'])) {
                                                                                    DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                    if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                      vehicles.add(e);
                                                                                      if (vehicles.isNotEmpty) {
                                                                                        var dist = calculateDistance(addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);

                                                                                        minsList.add(double.parse((dist / 1000).toString()));
                                                                                        var minDist = minsList.reduce(min);
                                                                                        if (minDist > 0 && minDist <= 1) {
                                                                                          minutes[etaDetails[i]['type_id']] = '2 mins';
                                                                                        } else if (minDist > 1 && minDist <= 3) {
                                                                                          minutes[etaDetails[i]['type_id']] = '5 mins';
                                                                                        } else if (minDist > 3 && minDist <= 5) {
                                                                                          minutes[etaDetails[i]['type_id']] = '8 mins';
                                                                                        } else if (minDist > 5 && minDist <= 7) {
                                                                                          minutes[etaDetails[i]['type_id']] = '11 mins';
                                                                                        } else if (minDist > 7 && minDist <= 10) {
                                                                                          minutes[etaDetails[i]['type_id']] = '14 mins';
                                                                                        } else if (minDist > 10) {
                                                                                          minutes[etaDetails[i]['type_id']] = '15 mins';
                                                                                        }
                                                                                      } else {
                                                                                        minutes[etaDetails[i]['type_id']] = '';
                                                                                      }
                                                                                    }
                                                                                  }
                                                                                },
                                                                              );
                                                                            } else {
                                                                              minutes[etaDetails[i]['type_id']] = '';
                                                                            }
                                                                          } else {
                                                                            minutes[etaDetails[i]['type_id']] =
                                                                                '';
                                                                          }
                                                                          return InkWell(
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                choosenVehicle = i;
                                                                              });
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              padding: EdgeInsets.fromLTRB(media.width * 0.04, media.width * 0.02, media.width * 0.04, media.width * 0.02),
                                                                              margin: EdgeInsets.only(top: 10, left: media.width * 0.02, right: media.width * 0.02),
                                                                              height: media.width * 0.165,
                                                                              decoration: BoxDecoration(
                                                                                borderRadius: BorderRadius.circular(15),
                                                                                color: (choosenVehicle != i)
                                                                                    ? (isDarkTheme == true)
                                                                                        ? Color(0xff1A1C1C)
                                                                                        : white
                                                                                    : buttonColor,
                                                                              ),
                                                                              child: Row(
                                                                                children: [
                                                                                  (etaDetails[i]['icon'] != null)
                                                                                      ? SizedBox(
                                                                                          width: media.width * 0.17,
                                                                                          height: media.width * 0.3,
                                                                                          child: Image.network(
                                                                                            etaDetails[i]['icon'],
                                                                                            fit: BoxFit.cover,
                                                                                          )
                                                                                      )
                                                                                      : Container(),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.05,
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                      children: [
                                                                                        Row(
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Text(
                                                                                                etaDetails[i]['name']?.toString() ?? '',
                                                                                                style: GoogleFonts.inter(
                                                                                                    fontSize: 13,
                                                                                                    fontWeight: FontWeight.w700,
                                                                                                    color: (choosenVehicle != i)
                                                                                                        ? (isDarkTheme == true)
                                                                                                        ? white
                                                                                                        : textColor
                                                                                                        : white),
                                                                                              ),
                                                                                            ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.02,
                                                                                          ),
                                                                                          InkWell(
                                                                                              onTap: () {
                                                                                                setState(() {
                                                                                                  _showInfoInt = i;
                                                                                                  _showInfo = true;
                                                                                                });
                                                                                              },
                                                                                              child: Icon(
                                                                                                Icons.info_rounded,
                                                                                                size: media.width * 0.04,
                                                                                                color: (choosenVehicle != i) ? Color(0xff7B7B7B) : white,
                                                                                              )
                                                                                          )
                                                                                        ],
                                                                                      ),
                                                                                        Flexible(
                                                                                          child: Row(
                                                                                            mainAxisSize: MainAxisSize.min,
                                                                                            children: [
                                                                                              Icon(
                                                                                                Icons.timelapse,
                                                                                                size: media.width * 0.04,
                                                                                                color: const Color(0xff8A8A8A),
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.01,
                                                                                              ),
                                                                                              (minutes[etaDetails[i]['type_id']] != null && minutes[etaDetails[i]['type_id']] != '')
                                                                                                  ? Text(
                                                                                                minutes[etaDetails[i]['type_id']].toString(),
                                                                                                style: GoogleFonts.inter(fontSize: media.width * twelve, color: const Color(0xff8A8A8A)),
                                                                                              )
                                                                                                  : const SizedBox.shrink(),
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                  (widget.type != 2)
                                                                                      ? Expanded(
                                                                                          child: (etaDetails[i]['has_discount'] != true)
                                                                                              ? Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                                  children: [
                                                                                                    InkWell(
                                                                                                      onTap: () {
                                                                                                        print(bearerToken[0].token);
                                                                                                        print(bearerToken[0].token.substring(500));
                                                                                                      },
                                                                                                      // APRÈS
                                                                                                      child: Text(
                                                                                                        "${etaDetails[i]['total'].toStringAsFixed(0)} ${etaDetails[i]['currency']}",
                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                        maxLines: 1,
                                                                                                        style: GoogleFonts.inter(
                                                                                                            fontSize: 14,
                                                                                                            fontWeight: FontWeight.w600,
                                                                                                            color: (choosenVehicle != i)
                                                                                                                ? (isDarkTheme == true)
                                                                                                                ? Colors.white
                                                                                                                : textColor
                                                                                                                : Colors.white),
                                                                                                      ),
                                                                                                    )
                                                                                                  ],
                                                                                                )
                                                                                              : Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                                  mainAxisSize: MainAxisSize.min,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      etaDetails[i]['currency'] + ' ',
                                                                                                      style: GoogleFonts.inter(fontSize: media.width * fourteen, color: (choosenVehicle != i) ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                                                                                                    ),
                                                                                                    Column(
                                                                                                      children: [
                                                                                                        Text(
                                                                                                          "${etaDetails[i]['total'].toStringAsFixed(0)}",
                                                                                                          style: GoogleFonts.inter(
                                                                                                              fontSize: media.width * fourteen,
                                                                                                              color: (choosenVehicle != i)
                                                                                                                  ? (isDarkTheme == true)
                                                                                                                      ? Colors.white
                                                                                                                      : textColor
                                                                                                                  : Colors.black,
                                                                                                              fontWeight: FontWeight.w600,
                                                                                                              decoration: TextDecoration.lineThrough),
                                                                                                        ),
                                                                                                        Text(
                                                                                                          '${etaDetails[i]['discounted_totel'].toStringAsFixed(0)}',
                                                                                                          style: GoogleFonts.inter(
                                                                                                              fontSize: media.width * fourteen,
                                                                                                              color: (choosenVehicle != i)
                                                                                                                  ? (isDarkTheme == true)
                                                                                                                      ? Colors.white
                                                                                                                      : textColor
                                                                                                                  : Colors.black,
                                                                                                              fontWeight: FontWeight.w600),
                                                                                                        )
                                                                                                      ],
                                                                                                    ),
                                                                                                  ],
                                                                                                ))
                                                                                      : Container()
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }));
                                                              })
                                                              .values
                                                              .toList(),
                                                        ))
                                                    : (etaDetails.isNotEmpty &&
                                                            widget.type == 1)
                                                        ? Expanded(
                                                            child: SizedBox(
                                                                width: media
                                                                        .width *
                                                                    1,
                                                                child: Column(
                                                                  children: [
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    SizedBox(
                                                                        width: media.width *
                                                                            0.9,
                                                                        child:
                                                                            SingleChildScrollView(
                                                                          scrollDirection:
                                                                              Axis.horizontal,
                                                                          child:
                                                                              Row(
                                                                            mainAxisAlignment:
                                                                                MainAxisAlignment.start,
                                                                            children: etaDetails
                                                                                .asMap()
                                                                                .map((i, value) {
                                                                                  return MapEntry(
                                                                                      i,
                                                                                      Container(
                                                                                        margin: EdgeInsets.only(right: media.width * 0.05),
                                                                                        decoration: BoxDecoration(
                                                                                            borderRadius: BorderRadius.circular(8),
                                                                                            color: (rentalChoosenOption == i)
                                                                                                ? buttonColor
                                                                                                : (isDarkTheme)
                                                                                                    ? hintColor
                                                                                                    : borderLines),
                                                                                        padding: EdgeInsets.all(media.width * 0.02),
                                                                                        child: InkWell(
                                                                                          onTap: () {
                                                                                            setState(() {
                                                                                              rentalOption = etaDetails[i]['typesWithPrice']['data'];
                                                                                              rentalChoosenOption = i;
                                                                                              choosenVehicle = null;
                                                                                              payingVia = 0;
                                                                                            });
                                                                                          },
                                                                                          child: Text(
                                                                                            etaDetails[i]['package_name'],
                                                                                            style: GoogleFonts.inter(
                                                                                                fontSize: media.width * sixteen,
                                                                                                fontWeight: FontWeight.w600,
                                                                                                color: (rentalChoosenOption == i)
                                                                                                    ? Colors.black
                                                                                                    : (isDarkTheme)
                                                                                                        ? Colors.white
                                                                                                        : Colors.black),
                                                                                          ),
                                                                                        ),
                                                                                      ));
                                                                                })
                                                                                .values
                                                                                .toList(),
                                                                          ),
                                                                        )),
                                                                    SizedBox(
                                                                        height: media.width *
                                                                            0.02),
                                                                    Expanded(
                                                                      child:
                                                                          SizedBox(
                                                                        width: media.width *
                                                                            0.9,
                                                                        child:
                                                                            SingleChildScrollView(
                                                                          // scrollDirection:
                                                                          //     Axis.horizontal,
                                                                          physics:
                                                                              const BouncingScrollPhysics(),
                                                                          child: Column(
                                                                              mainAxisAlignment: MainAxisAlignment.start,
                                                                              children: rentalOption
                                                                                  .asMap()
                                                                                  .map((i, value) {
                                                                                    return MapEntry(
                                                                                        i,
                                                                                        StreamBuilder<DatabaseEvent>(
                                                                                            stream: fdb.onValue,
                                                                                            builder: (context, AsyncSnapshot event) {
                                                                                              if (event.data != null) {
                                                                                                minutes[rentalOption[i]['type_id']] = '';
                                                                                                List vehicleList = [];
                                                                                                List vehicles = [];
                                                                                                List<double> minsList = [];
                                                                                                event.data!.snapshot.children.forEach((e) {
                                                                                                  vehicleList.add(e.value);
                                                                                                });
                                                                                                if (vehicleList.isNotEmpty) {
                                                                                                  // ignore: avoid_function_literals_in_foreach_calls
                                                                                                  vehicleList.forEach(
                                                                                                    (e) async {
                                                                                                      if (e['is_active'] == 1 && e['is_available'] == true && ((e['vehicle_types'] != null && e['vehicle_types'].contains(rentalOption[i]['type_id'])) || e['vehicle_type'] == rentalOption[i]['type_id'])) {
                                                                                                        DateTime dt = DateTime.fromMillisecondsSinceEpoch(e['updated_at']);
                                                                                                        if (DateTime.now().difference(dt).inMinutes <= 2) {
                                                                                                          vehicles.add(e);
                                                                                                          if (vehicles.isNotEmpty) {
                                                                                                            var dist = calculateDistance(addressList.firstWhere((e) => e.type == 'pickup').latlng.latitude, addressList.firstWhere((e) => e.type == 'pickup').latlng.longitude, e['l'][0], e['l'][1]);

                                                                                                            minsList.add(double.parse((dist / 1000).toString()));
                                                                                                            var minDist = minsList.reduce(min);
                                                                                                            if (minDist > 0 && minDist <= 1) {
                                                                                                              minutes[rentalOption[i]['type_id']] = '2 mins';
                                                                                                            } else if (minDist > 1 && minDist <= 3) {
                                                                                                              minutes[rentalOption[i]['type_id']] = '5 mins';
                                                                                                            } else if (minDist > 3 && minDist <= 5) {
                                                                                                              minutes[rentalOption[i]['type_id']] = '8 mins';
                                                                                                            } else if (minDist > 5 && minDist <= 7) {
                                                                                                              minutes[rentalOption[i]['type_id']] = '11 mins';
                                                                                                            } else if (minDist > 7 && minDist <= 10) {
                                                                                                              minutes[rentalOption[i]['type_id']] = '14 mins';
                                                                                                            } else if (minDist > 10) {
                                                                                                              minutes[rentalOption[i]['type_id']] = '15 mins';
                                                                                                            }
                                                                                                          } else {
                                                                                                            minutes[rentalOption[i]['type_id']] = '';
                                                                                                          }
                                                                                                        }
                                                                                                      }
                                                                                                    },
                                                                                                  );
                                                                                                } else {
                                                                                                  minutes[rentalOption[i]['type_id']] = '';
                                                                                                }
                                                                                              } else {
                                                                                                minutes[rentalOption[i]['type_id']] = '';
                                                                                              }
                                                                                              return InkWell(
                                                                                                  onTap: () {
                                                                                                    setState(() {
                                                                                                      choosenVehicle = i;
                                                                                                    });
                                                                                                  },
                                                                                                  child: Container(
                                                                                                    padding: EdgeInsets.all(media.width * 0.02),
                                                                                                    margin: EdgeInsets.only(top: 10, left: media.width * 0.05, right: media.width * 0.05),
                                                                                                    height: media.width * 0.152,
                                                                                                    decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(12),
                                                                                                      boxShadow: [
                                                                                                        BoxShadow(color: (isDarkTheme == true) ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2), spreadRadius: 2, blurRadius: 2)
                                                                                                      ],
                                                                                                      color: (choosenVehicle != i)
                                                                                                          ? (isDarkTheme == true)
                                                                                                              ? Colors.black
                                                                                                              : Colors.white
                                                                                                          : const Color(0xffF3F3F3),
                                                                                                    ),
                                                                                                    child: Row(
                                                                                                      children: [
                                                                                                        (rentalOption[i]['icon'] != null)
                                                                                                            ? SizedBox(
                                                                                                                width: media.width * 0.1,
                                                                                                                child: Image.network(
                                                                                                                  rentalOption[i]['icon'],
                                                                                                                  fit: BoxFit.contain,
                                                                                                                ))
                                                                                                            : Container(),
                                                                                                        SizedBox(
                                                                                                          width: media.width * 0.05,
                                                                                                        ),
                                                                                                        Column(
                                                                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                                                          children: [
                                                                                                            Text(rentalOption[i]['name'],
                                                                                                                style: GoogleFonts.inter(
                                                                                                                    fontSize: media.width * fourteen,
                                                                                                                    fontWeight: FontWeight.w600,
                                                                                                                    color: (choosenVehicle != i)
                                                                                                                        ? (isDarkTheme == true)
                                                                                                                            ? hintColor
                                                                                                                            : textColor
                                                                                                                        : Colors.black)),
                                                                                                            Row(
                                                                                                              children: [
                                                                                                                Icon(
                                                                                                                  Icons.timelapse,
                                                                                                                  size: media.width * 0.04,
                                                                                                                  color: const Color(0xff8A8A8A),
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.01,
                                                                                                                ),
                                                                                                                (minutes[rentalOption[i]['type_id']] != null && minutes[rentalOption[i]['type_id']] != '')
                                                                                                                    ? Text(
                                                                                                                        minutes[rentalOption[i]['type_id']].toString(),
                                                                                                                        style: GoogleFonts.inter(fontSize: media.width * twelve, color: const Color(0xff8A8A8A)),
                                                                                                                      )
                                                                                                                    : Text(
                                                                                                                  '${etaDetails[i]['distance']} ${etaDetails[i]['unit_in_words']}',
                                                                                                                  style: GoogleFonts.inter(fontSize: media.width * twelve, color: const Color(0xff8A8A8A)),
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: media.width * 0.01,
                                                                                                                ),
                                                                                                                InkWell(
                                                                                                                    onTap: () {
                                                                                                                      setState(() {
                                                                                                                        _showInfoInt = i;
                                                                                                                        _showInfo = true;
                                                                                                                      });
                                                                                                                    },
                                                                                                                    child: Icon(
                                                                                                                      Icons.info_outline,
                                                                                                                      size: media.width * 0.04,
                                                                                                                      color: const Color(0xff8A8A8A),
                                                                                                                    ))
                                                                                                              ],
                                                                                                            ),
                                                                                                          ],
                                                                                                        ),
                                                                                                        Expanded(
                                                                                                            child: (rentalOption[i]['has_discount'] != true)
                                                                                                                ? Row(
                                                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                    children: [
                                                                                                                      Text(
                                                                                                                        rentalOption[i]['currency'] + ' ' + rentalOption[i]['fare_amount'].toStringAsFixed(0),
                                                                                                                        style: GoogleFonts.inter(
                                                                                                                            fontSize: media.width * fourteen,
                                                                                                                            fontWeight: FontWeight.w600,
                                                                                                                            color: (choosenVehicle != i)
                                                                                                                                ? (isDarkTheme == true)
                                                                                                                                    ? Colors.white
                                                                                                                                    : textColor
                                                                                                                                : Colors.black),
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  )
                                                                                                                : Row(
                                                                                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                                                                                    children: [
                                                                                                                      Text(
                                                                                                                        rentalOption[i]['currency'] + ' ',
                                                                                                                        style: GoogleFonts.inter(fontSize: media.width * fourteen, color: (choosenVehicle != i) ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                                                                                                                      ),
                                                                                                                      Column(
                                                                                                                        children: [
                                                                                                                          Text(
                                                                                                                            rentalOption[i]['currency'] + ' ' + rentalOption[i]['fare_amount'].toStringAsFixed(0),
                                                                                                                            style: GoogleFonts.inter(
                                                                                                                                fontSize: media.width * fourteen,
                                                                                                                                color: (choosenVehicle != i)
                                                                                                                                    ? (isDarkTheme == true)
                                                                                                                                        ? Colors.white
                                                                                                                                        : textColor
                                                                                                                                    : Colors.black,
                                                                                                                                fontWeight: FontWeight.w600,
                                                                                                                                decoration: TextDecoration.lineThrough),
                                                                                                                          ),
                                                                                                                          Text(
                                                                                                                            rentalOption[i]['currency'] + ' ' + rentalOption[i]['discounted_totel'].toStringAsFixed(0),
                                                                                                                            style: GoogleFonts.inter(
                                                                                                                                fontSize: media.width * fourteen,
                                                                                                                                color: (choosenVehicle != i)
                                                                                                                                    ? (isDarkTheme == true)
                                                                                                                                        ? Colors.white
                                                                                                                                        : textColor
                                                                                                                                    : Colors.black,
                                                                                                                                fontWeight: FontWeight.w600),
                                                                                                                          )
                                                                                                                        ],
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  ))
                                                                                                      ],
                                                                                                    ),
                                                                                                  ));
                                                                                            }));
                                                                                  })
                                                                                  .values
                                                                                  .toList()),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                )),
                                                          )
                                                        : Container(),
                                                SizedBox(
                                                  height: media.width * 0.02,
                                                ),
                                                (choosenVehicle != null &&
                                                        widget.type != 1)
                                                    ? SizedBox()
                                                    : (choosenVehicle != null &&
                                                            widget.type == 1)
                                                        ? Container(
                                                            height:
                                                                media.width *
                                                                    0.106,
                                                            width: media.width *
                                                                0.9,
                                                            color: (isDarkTheme ==
                                                                    true)
                                                                ? page
                                                                : const Color(
                                                                    0xffF3F3F3),
                                                            child:
                                                                SingleChildScrollView(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              child: Row(
                                                                children: rentalOption[
                                                                            choosenVehicle]
                                                                        [
                                                                        'payment_type']
                                                                    .toString()
                                                                    .split(',')
                                                                    .toList()
                                                                    .asMap()
                                                                    .map((i,
                                                                        value) {
                                                                      return MapEntry(
                                                                          i,
                                                                          InkWell(
                                                                            onTap:
                                                                                () {
                                                                              setState(() {
                                                                                payingVia = i;
                                                                              });
                                                                            },
                                                                            child:
                                                                                Container(
                                                                              height: media.width * 0.106,
                                                                              width: media.width * 0.3,
                                                                              decoration: BoxDecoration(border: Border(right: BorderSide(color: (i < rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList().length - 1) ? const Color(0xffE7EDEF) : Colors.transparent, width: 1.1))),
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.center,
                                                                                children: [
                                                                                  (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                      ? Image.asset(
                                                                                          'assets/images/cash.png',
                                                                                          width: media.width * 0.037,
                                                                                          height: media.width * 0.037,
                                                                                          fit: BoxFit.contain,
                                                                                          color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                        )
                                                                                      : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                          ? Image.asset(
                                                                                              'assets/images/wallet.png',
                                                                                              width: media.width * 0.037,
                                                                                              height: media.width * 0.037,
                                                                                              color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                              fit: BoxFit.contain,
                                                                                            )
                                                                                          : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                              ? Image.asset(
                                                                                                  'assets/images/card.png',
                                                                                                  width: media.width * 0.037,
                                                                                                  height: media.width * 0.037,
                                                                                                  color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                                  fit: BoxFit.contain,
                                                                                                )
                                                                                              : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                  ? Image.asset(
                                                                                                      'assets/images/upi.png',
                                                                                                      width: media.width * 0.037,
                                                                                                      height: media.width * 0.037,
                                                                                                      color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                                      fit: BoxFit.contain,
                                                                                                    )
                                                                                                  : Container(),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.02,
                                                                                  ),
                                                                                  MyText(
                                                                                    text: rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i],
                                                                                    size: media.width * fourteen,
                                                                                    color: (payingVia == i) ? const Color(0xffFF0000) : Colors.black,
                                                                                  )
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ));
                                                                    })
                                                                    .values
                                                                    .toList(),
                                                              ),
                                                            ),
                                                          )
                                                        : Container(),
                                                (selectedGoodsId != '')
                                                    ? Container(
                                                        padding:
                                                            EdgeInsets.only(
                                                                top: media
                                                                        .width *
                                                                    0.03),
                                                        width:
                                                            media.width * 0.9,
                                                        child: Column(
                                                          children: [
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              child: Text(
                                                                languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_goods_type'],
                                                                style:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: media
                                                                          .width *
                                                                      fourteen,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                            SizedBox(
                                                                height: media
                                                                        .width *
                                                                    0.02),
                                                            InkWell(
                                                              onTap: () async {
                                                                var val = await Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                const ChooseGoods()));
                                                                if (val) {
                                                                  setState(
                                                                      () {});
                                                                }
                                                              },
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.7,
                                                                    child: Text(
                                                                      goodsTypeList.firstWhere((e) =>
                                                                              e['id'] ==
                                                                              int.parse(selectedGoodsId))['goods_type_name'] +
                                                                          ' (' +
                                                                          goodsSize +
                                                                          ')',
                                                                      style: GoogleFonts.inter(
                                                                          fontSize: media.width *
                                                                              twelve,
                                                                          color:
                                                                              buttonColor),
                                                                      maxLines:
                                                                          1,
                                                                      overflow:
                                                                          TextOverflow
                                                                              .ellipsis,
                                                                    ),
                                                                  ),
                                                                  Icon(
                                                                    Icons
                                                                        .arrow_forward_ios,
                                                                    size: media
                                                                            .width *
                                                                        0.04,
                                                                    color:
                                                                        buttonColor,
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      )
                                                    : Container(),
                                                Container(
                                                  margin: EdgeInsets.only(
                                                      top: 10,
                                                      left: media.width * 0.02,
                                                      right:
                                                          media.width * 0.02),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      (choosenVehicle != null &&
                                                                  widget.type !=
                                                                      1) &&
                                                              _addCoupon ==
                                                                  false
                                                          ? InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _showChoosePaymentMethodSheet =
                                                                      true;
                                                                });
                                                              },
                                                              child: Container(
                                                                height: media
                                                                        .width *
                                                                    0.106,
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .center,
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  children: [
                                                                    MyText(
                                                                      text: languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_apply_pay'],
                                                                      size: media
                                                                              .width *
                                                                          fourteen,
                                                                      fontweight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                    SizedBox(
                                                                      width: 5,
                                                                    ),
                                                                    Icon(
                                                                      Icons
                                                                          .keyboard_arrow_down_rounded,
                                                                      color:
                                                                          textColor,
                                                                      size: media
                                                                              .width *
                                                                          0.07,
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                            )
                                                          : SizedBox(),
                                                      (choosenVehicle != null &&
                                                              widget.type != 2)
                                                          ? InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _addCoupon =
                                                                      true;
                                                                });
                                                              },
                                                              child: (_addCoupon ==
                                                                      false)
                                                                  ? Container(
                                                                      height: media
                                                                              .width *
                                                                          0.106,
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.end,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        mainAxisSize:
                                                                            MainAxisSize.min,
                                                                        children: [
                                                                          MyText(
                                                                            text:
                                                                                languages[choosenLanguage]['text_add_coupons'],
                                                                            size:
                                                                                media.width * fourteen,
                                                                            fontweight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                10,
                                                                          ),
                                                                          Icon(
                                                                            Icons.arrow_forward_ios,
                                                                            color:
                                                                                textColor,
                                                                            size:
                                                                                media.width * 0.04,
                                                                          )
                                                                        ],
                                                                      ),
                                                                    )
                                                                  : Container(
                                                                      padding: EdgeInsets.all(
                                                                          media.width *
                                                                              0.02),
                                                                      height: media
                                                                              .width *
                                                                          0.13,
                                                                      width: media
                                                                              .width *
                                                                          0.9,
                                                                      decoration: BoxDecoration(
                                                                          color: (isDarkTheme == true)
                                                                              ? darkModeDialogColor
                                                                              : const Color(
                                                                                  0xffF3F3F3),
                                                                          borderRadius: BorderRadius.circular(
                                                                              14),
                                                                          border:
                                                                              Border.all(color: darkModeBorderColor.withAlpha(80))),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceEvenly,
                                                                        children: [
                                                                          MyText(
                                                                              text: languages[choosenLanguage]['text_coupons'],
                                                                              size: 15,
                                                                              fontweight: FontWeight.w600,
                                                                              color: textColor),
                                                                          (promoStatus != 1)
                                                                              ? Container(
                                                                                  alignment: Alignment.center,
                                                                                  width: media.width * 0.3,
                                                                                  height: media.width * 0.090,
                                                                                  padding: EdgeInsets.only(left: media.width * 0.04),
                                                                                  decoration: BoxDecoration(color: black, borderRadius: BorderRadius.circular(8)),
                                                                                  child: TextField(
                                                                                    controller: promoKey,
                                                                                    style: TextStyle(fontWeight: FontWeight.w400),
                                                                                    decoration: const InputDecoration(border: InputBorder.none),
                                                                                    onChanged: (val) {
                                                                                      promoCode = val;
                                                                                    },
                                                                                  ),
                                                                                )
                                                                              : const Icon(
                                                                                  Icons.done,
                                                                                  color: Colors.green,
                                                                                ),
                                                                          Button(
                                                                            width:
                                                                                media.width * 0.18,
                                                                            height:
                                                                                media.width * 0.090,
                                                                            text: (promoStatus != 1)
                                                                                ? languages[choosenLanguage]['text_apply']
                                                                                : languages[choosenLanguage]['text_remove'],
                                                                            leftPadding:
                                                                                Responsive.width(2.5, context),
                                                                            rightPadding:
                                                                                Responsive.width(2.5, context),
                                                                            fontweight:
                                                                                FontWeight.w500,
                                                                            fontSize:
                                                                                15,
                                                                            onTap:
                                                                                () async {
                                                                              FocusScope.of(context).unfocus();
                                                                              setState(() {
                                                                                _isLoading = true;
                                                                              });
                                                                              if (promoStatus != 1) {
                                                                                setState(() {
                                                                                  promoStatus = null;
                                                                                });
                                                                                if (widget.type != 1 && promoKey.text.isNotEmpty) {
                                                                                  await etaRequestWithPromo();
                                                                                } else if (widget.type == 1 && promoKey.text.isNotEmpty) {
                                                                                  await rentalRequestWithPromo();
                                                                                }
                                                                              } else {
                                                                                promoKey.text = '';
                                                                                promoStatus = null;
                                                                                if (widget.type != 1) {
                                                                                  await etaRequest();
                                                                                } else if (widget.type == 1) {
                                                                                  await rentalEta();
                                                                                }
                                                                              }
                                                                              setState(() {
                                                                                _isLoading = false;
                                                                              });
                                                                            },
                                                                            color:
                                                                                buttonColor,
                                                                            textcolor:
                                                                                white,
                                                                            borderRadius:
                                                                                9.0,
                                                                          ),
                                                                          InkWell(
                                                                              onTap: () {
                                                                                setState(() {
                                                                                  promoStatus = false;
                                                                                  _addCoupon = false;
                                                                                });
                                                                              },
                                                                              child: Icon(
                                                                                Icons.cancel_outlined,
                                                                                color: textColor.withOpacity(0.5),
                                                                              ))
                                                                        ],
                                                                      ),
                                                                    ),
                                                            )
                                                          : Container(),
                                                    ],
                                                  ),
                                                ),
                                                if (promoStatus != null &&
                                                    promoStatus == 2)
                                                  Container(
                                                    width: media.width * 0.9,
                                                    padding: EdgeInsets.only(
                                                        top: media.width *
                                                            0.025),
                                                    child: MyText(
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_promorejected'],
                                                      size:
                                                          media.width * twelve,
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                (choosenVehicle != null)
                                                    ? SizedBox(
                                                        height:
                                                            media.width * 0.025,
                                                      )
                                                    : Container(),
                                                SizedBox(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Button(
                                                          width:
                                                              media.width * 0.9,
                                                          // width: ((userDetails[
                                                          //             'show_ride_later_feature'] ==
                                                          //         true))
                                                          //     ? media.width *
                                                          //         0.67
                                                          //     : media.width *
                                                          //         0.89,
                                                          color: buttonColor,
                                                          onTap: () async {
                                                            if (choosenVehicle !=
                                                                null) {
                                                              if (((rentalOption.isEmpty && (etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['total'] && etaDetails[choosenVehicle]['has_discount'] == false) ||
                                                                          (rentalOption.isEmpty &&
                                                                              etaDetails[choosenVehicle]['has_discount'] ==
                                                                                  true &&
                                                                              etaDetails[choosenVehicle]['user_wallet_balance'] >=
                                                                                  etaDetails[choosenVehicle][
                                                                                      'discounted_totel'])) ||
                                                                      (rentalOption.isEmpty &&
                                                                          etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] !=
                                                                              'wallet')) ||
                                                                  ((rentalOption.isNotEmpty && etaDetails[0]['user_wallet_balance'] >= rentalOption[choosenVehicle]['fare_amount'] && rentalOption[choosenVehicle]['has_discount'] == false) ||
                                                                      (rentalOption.isNotEmpty &&
                                                                          rentalOption[choosenVehicle]['has_discount'] ==
                                                                              true &&
                                                                          rentalOption[choosenVehicle]['user_wallet_balance'] >=
                                                                              rentalOption[choosenVehicle][
                                                                                  'discounted_totel']) ||
                                                                      rentalOption
                                                                              .isNotEmpty &&
                                                                          rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] !=
                                                                              'wallet')) {
                                                                setState(() {
                                                                  _isLoading =
                                                                      true;
                                                                });
                                                                dropStopList
                                                                    .clear();
                                                                dynamic result;
                                                                if (choosenVehicle !=
                                                                    null) {
                                                                  if (widget
                                                                          .type !=
                                                                      1) {
                                                                    if (etaDetails[choosenVehicle]
                                                                            [
                                                                            'has_discount'] ==
                                                                        false) {
                                                                      if (addressList
                                                                              .length >
                                                                          2) {
                                                                        for (var i =
                                                                                1;
                                                                            i < addressList.length;
                                                                            i++) {
                                                                          dropStopList.add(DropStops(
                                                                              order: i.toString(),
                                                                              latitude: addressList[i].latlng.latitude,
                                                                              longitude: addressList[i].latlng.longitude,
                                                                              address: addressList[i].address));
                                                                        }
                                                                      }
                                                                      result =
                                                                          await createRequest();
                                                                      if (result ==
                                                                          'logout') {
                                                                        navigateLogout();
                                                                      }
                                                                    } else {
                                                                      if (addressList
                                                                              .length >
                                                                          2) {
                                                                        for (var i =
                                                                                1;
                                                                            i < addressList.length;
                                                                            i++) {
                                                                          dropStopList.add(DropStops(
                                                                              order: i.toString(),
                                                                              latitude: addressList[i].latlng.latitude,
                                                                              longitude: addressList[i].latlng.longitude,
                                                                              address: addressList[i].address));
                                                                        }
                                                                      }
                                                                      result =
                                                                          await createRequestWithPromo();
                                                                      if (result ==
                                                                          'logout') {
                                                                        navigateLogout();
                                                                      }
                                                                    }
                                                                  } else {
                                                                    if (rentalOption[choosenVehicle]
                                                                            [
                                                                            'has_discount'] ==
                                                                        false) {
                                                                      result =
                                                                          await createRentalRequest();
                                                                      if (result ==
                                                                          'logout') {
                                                                        navigateLogout();
                                                                      }
                                                                    } else {
                                                                      result =
                                                                          await createRentalRequestWithPromo();
                                                                      if (result ==
                                                                          'logout') {
                                                                        navigateLogout();
                                                                      }
                                                                    }
                                                                  }
                                                                }
                                                                if (result ==
                                                                    'success') {
                                                                  timer();
                                                                }
                                                                if (destinationLocation !=
                                                                    null) {
                                                                  FirebaseDatabase
                                                                      .instance
                                                                      .ref(
                                                                          'requests/${userRequestData['id']}')
                                                                      .update({
                                                                    'destination_location':
                                                                        {
                                                                      'lat': destinationLocation!
                                                                          .latitude,
                                                                      'lng': destinationLocation!
                                                                          .longitude
                                                                    }
                                                                  });
                                                                }
                                                                setState(() {
                                                                  _isLoading =
                                                                      false;
                                                                });
                                                              } else {
                                                                setState(() {
                                                                  islowwalletbalance =
                                                                      true;
                                                                });
                                                              }
                                                            }
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_book_now']),
                                                      // (userDetails[
                                                      //             'show_ride_later_feature'] ==
                                                      //         true)
                                                      //     ? InkWell(
                                                      //         onTap: () async {
                                                      //           if (choosenVehicle !=
                                                      //               null) {
                                                      //             setState(() {
                                                      //               choosenDateTime = DateTime
                                                      //                       .now()
                                                      //                   .add(const Duration(
                                                      //                       minutes:
                                                      //                           30));
                                                      //               _dateTimePicker =
                                                      //                   true;
                                                      //             });
                                                      //           }
                                                      //         },
                                                      //         child: Container(
                                                      //           width: media
                                                      //                   .width *
                                                      //               0.20,
                                                      //           height: media
                                                      //                   .width *
                                                      //               0.12,
                                                      //           decoration:
                                                      //               BoxDecoration(
                                                      //             borderRadius:
                                                      //                 BorderRadius
                                                      //                     .circular(
                                                      //                         16),
                                                      //             border: Border
                                                      //                 .all(
                                                      //                     color:
                                                      //                         darkModeBorderColor.withAlpha(
                                                      //               100,
                                                      //             )),
                                                      //           ),
                                                      //           child: Icon(
                                                      //             Icons
                                                      //                 .date_range_outlined,
                                                      //             color: white,
                                                      //             size: Responsive
                                                      //                 .width(8,
                                                      //                     context),
                                                      //           ),
                                                      //         ),
                                                      //       )
                                                      //     // ? Button(
                                                      //
                                                      //     //     color: page,
                                                      //     //     borcolor:
                                                      //     //         darkModeBorderColor
                                                      //     //             .withAlpha(
                                                      //     //                 100),
                                                      //     //     textcolor:
                                                      //     //         buttonColor,
                                                      //     //     width:
                                                      //     //         media.width *
                                                      //     //             0.24,
                                                      //     //     onTap: () async {
                                                      //     //       if (choosenVehicle !=
                                                      //     //           null) {
                                                      //     //         setState(() {
                                                      //     //           choosenDateTime = DateTime
                                                      //     //                   .now()
                                                      //     //               .add(const Duration(
                                                      //     //                   minutes:
                                                      //     //                       30));
                                                      //     //           _dateTimePicker =
                                                      //     //               true;
                                                      //     //         });
                                                      //     //       }
                                                      //     //     },
                                                      //
                                                      //     //     text: languages[
                                                      //     //             choosenLanguage]
                                                      //     //         [
                                                      //     //         'text_ridelater'])
                                                      //     : Container(),
                                                    ],
                                                  ),
                                                ),
                                                ButtonBottomSpace(
                                                  height: 3,
                                                )
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //show choose payment method

                                  (_showChoosePaymentMethodSheet == true)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            alignment: Alignment.bottomCenter,
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Container(
                                              height: media.height * 0.6,
                                              width: media.width * 1,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                          top: Radius.circular(
                                                              20)),
                                                  color: darkModeDialogColor),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: media.height * 0.04,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            left: media.width *
                                                                0.05,
                                                  ),
                                                        child: MyText(
                                                          text: languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_choose_payment_method'],
                                                          size: 21,
                                                          fontweight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                      Button(
                                                          borcolor: Colors
                                                              .transparent,
                                                          onTap: () {
                                                            setState(() {
                                                              _showChoosePaymentMethodSheet =
                                                                  false;
                                                            });
                                                          },
                                                          color: Colors
                                                              .transparent,
                                                          textcolor:
                                                              buttonColor,
                                                          fontSize:
                                                              media.width *
                                                                  nineteen,
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_done']),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: media.height * 0.02,
                                                  ),
                                                  Container(
                                                    width: media.width * 0.9,
                                                    height:
                                                        media.height * 0.135,
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            Responsive.width(
                                                                3, context),
                                                            Responsive.height(
                                                                2, context),
                                                            Responsive.width(
                                                                3, context),
                                                            Responsive.width(
                                                                2, context)),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        border: Border.all(
                                                            color: white
                                                                .withOpacity(
                                                                    0.3))),
                                                    child: Container(
                                                      margin: EdgeInsets.only(
                                                          left: media.width *
                                                              0.01,
                                                          right: media.width *
                                                              0.01),
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_wallet_balance'],
                                                            size: 18,
                                                            color: textColor
                                                                .withOpacity(
                                                                    0.42),
                                                          ),
                                                          MyText(
                                                            text:
                                                                '${etaDetails[0]['currency']} ${etaDetails[choosenVehicle]['user_wallet_balance']}',
                                                            size: media.width *
                                                                twentyeight,
                                                            color: textColor,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: media.height * 0.03,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      Container(
                                                        margin: EdgeInsets.only(
                                                            left: media.width *
                                                                0.05,
                                                            right: media.width *
                                                                0.05),
                                                        child: MyText(
                                                          text: languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_payment_method'],
                                                          size: 21,
                                                          fontweight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: media.height * 0.02,
                                                  ),
                                                  Container(
                                                    width: media.width * 0.9,
                                                    color: (isDarkTheme == true)
                                                        ? darkModeDialogColor
                                                        : const Color(
                                                            0xffF3F3F3),
                                                    child:
                                                        SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.vertical,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: etaDetails[
                                                                    choosenVehicle]
                                                                ['payment_type']
                                                            .toString()
                                                            .split(',')
                                                            .toList()
                                                            .asMap()
                                                            .map((i, value) {
                                                              return MapEntry(
                                                                  i,
                                                                  InkWell(
                                                                    onTap: () {
                                                                      setState(
                                                                          () {
                                                                        payingVia =
                                                                            i;
                                                                      });
                                                                    },
                                                                    child:
                                                                        Stack(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerRight,
                                                                      children: [
                                                                        Column(
                                                                          crossAxisAlignment:
                                                                              CrossAxisAlignment.start,
                                                                          children: [
                                                                            Container(
                                                                              height: media.height * 0.05,
                                                                              width: etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList().length == 2 ? media.width * 0.45 : media.width * 0.3,
                                                                              // decoration:
                                                                              //     BoxDecoration(
                                                                              //         border: Border(right: BorderSide(color: (i < etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList().length - 1) ? const Color(0xffE7EDEF) : Colors.transparent, width: 1.1))),
                                                                              child: Row(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                children: [
                                                                                  (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                      ? Image.asset(
                                                                                          'assets/images/cash_image.png',
                                                                                          width: media.width * 0.06,
                                                                                          height: media.width * 0.06,
                                                                                          fit: BoxFit.contain,
                                                                                          color: (payingVia == i)
                                                                                              ? Colors.white
                                                                                              : (isDarkTheme == true)
                                                                                                  ? Colors.white
                                                                                                  : Colors.black,
                                                                                        )
                                                                                      : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                          ? Image.asset(
                                                                                              'assets/images/wallet_image.png',
                                                                                              width: media.width * 0.06,
                                                                                              height: media.width * 0.06,
                                                                                              color: (payingVia == i)
                                                                                                  ? Colors.white
                                                                                                  : (isDarkTheme == true)
                                                                                                      ? Colors.white
                                                                                                      : Colors.black,
                                                                                              fit: BoxFit.contain,
                                                                                            )
                                                                                          : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                              ? Image.asset(
                                                                                                  'assets/images/card_image.png',
                                                                                                  width: media.width * 0.07,
                                                                                                  height: media.width * 0.07,
                                                                                                  color: (payingVia == i)
                                                                                                      ? Colors.white
                                                                                                      : (isDarkTheme == true)
                                                                                                          ? Colors.white
                                                                                                          : Colors.black,
                                                                                                  fit: BoxFit.contain,
                                                                                                )
                                                                                              : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                  ? Image.asset(
                                                                                                      'assets/images/upi.png',
                                                                                                      width: media.width * 0.06,
                                                                                                      height: media.width * 0.06,
                                                                                                      color: (payingVia == i)
                                                                                                          ? buttonColor
                                                                                                          : (isDarkTheme == true)
                                                                                                              ? Colors.white
                                                                                                              : Colors.black,
                                                                                                      fit: BoxFit.contain,
                                                                                                    )
                                                                                                  : Container(),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.02,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.2,
                                                                                    child: MyText(
                                                                                      text: etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i],
                                                                                      size: media.width * sixteen,
                                                                                      color: (payingVia == i)
                                                                                          ? Colors.white
                                                                                          : (isDarkTheme == true)
                                                                                              ? Colors.white
                                                                                              : Colors.black,
                                                                                    ),
                                                                                  )
                                                                                ],
                                                                              ),
                                                                            ),
                                                                            Container(
                                                                              height: 1,
                                                                              width: media.width * 0.9,
                                                                              color: darkModeBorderColor,
                                                                            )
                                                                          ],
                                                                        ),
                                                                        Visibility(
                                                                          visible:
                                                                              payingVia == i,
                                                                          child:
                                                                              Container(
                                                                            alignment:
                                                                                Alignment.center,
                                                                            width:
                                                                                media.width * 0.047,
                                                                            height:
                                                                                media.width * 0.047,
                                                                            decoration:
                                                                                BoxDecoration(color: buttonColor, shape: BoxShape.circle),
                                                                            child:
                                                                                Icon(
                                                                              Icons.done,
                                                                              color: darkModeDialogColor,
                                                                              size: media.width * 0.037,
                                                                            ),
                                                                          ),
                                                                        )
                                                                      ],
                                                                    ),
                                                                  ));
                                                            })
                                                            .values
                                                            .toList(),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(),

                                  //show vehicle info
                                  (_showInfo == true)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            alignment: Alignment.bottomCenter,
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisAlignment:
                                                MainAxisAlignment.end,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      Builder(builder: (context) {
                                                        print(etaDetails[
                                                        _showInfoInt]);
                                                      return Container(
                                                        width: media.width,
                                                        // height:
                                                        //     media.height * 0.55,
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.vertical(
                                                                    top: Radius
                                                                        .circular(
                                                                            30)),
                                                            color:
                                                                darkModeDialogColor),
                                                        padding: EdgeInsets.all(
                                                            media.width * 0.08),
                                                        child:
                                                            (widget.type != 1)
                                                                ? Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        etaDetails[_showInfoInt]
                                                                            [
                                                                            'name'],
                                                                        style: GoogleFonts.inter(
                                                                            fontSize:
                                                                                25,
                                                                            color:
                                                                                textColor,
                                                                            fontWeight:
                                                                                FontWeight.w800),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.025,
                                                                      ),
                                                                      SizedBox(
                                                                        width: Responsive.width(
                                                                            40,
                                                                            context),
                                                                        child:
                                                                            Text(
                                                                          etaDetails[_showInfoInt]
                                                                              [
                                                                              'short_description'],
                                                                          style:
                                                                              GoogleFonts.inter(
                                                                            fontSize:
                                                                                media.width * fourteen,
                                                                            color:
                                                                                textColor,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              media.width * 0.1),
                                                                      Text(
                                                                        etaDetails[_showInfoInt]
                                                                            [
                                                                            'type_name'],
                                                                        style: GoogleFonts.inter(
                                                                            fontSize:
                                                                                18,
                                                                            color:
                                                                                textColor,
                                                                            fontWeight:
                                                                                FontWeight.w700),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.height *
                                                                            0.035,
                                                                      ),
                                                                      Text(
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_supported_vehicles'],
                                                                        style: GoogleFonts.inter(
                                                                            fontSize:
                                                                                16,
                                                                            color:
                                                                                textColor,
                                                                            fontWeight:
                                                                                FontWeight.w700),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.01,
                                                                      ),
                                                                      Text(
                                                                        etaDetails[_showInfoInt]['type_name']?.toString() ?? '',
                                                                        style: GoogleFonts.inter(
                                                                            fontSize: 18,
                                                                            color: textColor,
                                                                            fontWeight: FontWeight.w700),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.height * 0.035,
                                                                      ),
                                                                      Text(
                                                                        languages[choosenLanguage]['text_supported_vehicles'],
                                                                        style: GoogleFonts.inter(
                                                                            fontSize: 16,
                                                                            color: textColor,
                                                                            fontWeight: FontWeight.w700),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width * 0.01,
                                                                      ),
                                                                      Text(
                                                                        etaDetails[_showInfoInt]['supported_vehicles']?.toString() ?? '',
                                                                        style: GoogleFonts.inter(
                                                                          fontWeight: FontWeight.w500,
                                                                          fontSize: 14,
                                                                          color: Color(0xff929292),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.height *
                                                                            0.035,
                                                                      ),
                                                                      Column(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.4,
                                                                            child:
                                                                                Text(
                                                                              languages[choosenLanguage]['text_estimated_amount'],
                                                                              style: GoogleFonts.inter(fontSize: 16, color: textColor, fontWeight: FontWeight.w700),
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.01,
                                                                          ),
                                                                          (etaDetails[_showInfoInt]['has_discount'] != true)
                                                                              ? Row(
                                                                                  children: [
                                                                                    Text(
                                                                                      etaDetails[_showInfoInt]['currency'] + ' ' + etaDetails[_showInfoInt]['total'].toStringAsFixed(0),
                                                                                      style: GoogleFonts.inter(fontSize: 16, color: textColor, fontWeight: FontWeight.w700),
                                                                                    ),
                                                                                  ],
                                                                                )
                                                                              : Row(
                                                                                  children: [
                                                                                    Text(
                                                                                      etaDetails[_showInfoInt]['currency'] + ' ',
                                                                                      style: GoogleFonts.inter(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                    Text(
                                                                                      etaDetails[_showInfoInt]['total'].toStringAsFixed(0),
                                                                                      style: GoogleFonts.inter(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                                                                    ),
                                                                                    Text(
                                                                                      ' ${etaDetails[_showInfoInt]['discounted_totel'].toStringAsFixed(0)}',
                                                                                      style: GoogleFonts.inter(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                          SizedBox(
                                                                            height:
                                                                                Responsive.height(3, context),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                media.width * 0.9,
                                                                            child:
                                                                                Row(
                                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                              children: [
                                                                                Expanded(
                                                                                child: Button(
                                                                                width: null,
                                                                                    color: buttonColor,
                                                                                    onTap: () async {
                                                                                      if (choosenVehicle != null) {
                                                                                        if (((rentalOption.isEmpty && (etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['total'] && etaDetails[choosenVehicle]['has_discount'] == false) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['has_discount'] == true && etaDetails[choosenVehicle]['user_wallet_balance'] >= etaDetails[choosenVehicle]['discounted_totel'])) || (rentalOption.isEmpty && etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet')) || ((rentalOption.isNotEmpty && etaDetails[0]['user_wallet_balance'] >= rentalOption[choosenVehicle]['fare_amount'] && rentalOption[choosenVehicle]['has_discount'] == false) || (rentalOption.isNotEmpty && rentalOption[choosenVehicle]['has_discount'] == true && rentalOption[choosenVehicle]['user_wallet_balance'] >= rentalOption[choosenVehicle]['discounted_totel']) || rentalOption.isNotEmpty && rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[payingVia] != 'wallet')) {
                                                                                          setState(() {
                                                                                            _isLoading = true;
                                                                                          });
                                                                                          dropStopList.clear();
                                                                                          dynamic result;
                                                                                          if (choosenVehicle != null) {
                                                                                            if (widget.type != 1) {
                                                                                              if (etaDetails[choosenVehicle]['has_discount'] == false) {
                                                                                                if (addressList.length > 2) {
                                                                                                  for (var i = 1; i < addressList.length; i++) {
                                                                                                    dropStopList.add(DropStops(order: i.toString(), latitude: addressList[i].latlng.latitude, longitude: addressList[i].latlng.longitude, address: addressList[i].address));
                                                                                                  }
                                                                                                }
                                                                                                result = await createRequest();
                                                                                                if (result == 'logout') {
                                                                                                  navigateLogout();
                                                                                                }
                                                                                              } else {
                                                                                                if (addressList.length > 2) {
                                                                                                  for (var i = 1; i < addressList.length; i++) {
                                                                                                    dropStopList.add(DropStops(order: i.toString(), latitude: addressList[i].latlng.latitude, longitude: addressList[i].latlng.longitude, address: addressList[i].address));
                                                                                                  }
                                                                                                }
                                                                                                result = await createRequestWithPromo();
                                                                                                if (result == 'logout') {
                                                                                                  navigateLogout();
                                                                                                }
                                                                                              }
                                                                                            } else {
                                                                                              if (rentalOption[choosenVehicle]['has_discount'] == false) {
                                                                                                result = await createRentalRequest();
                                                                                                if (result == 'logout') {
                                                                                                  navigateLogout();
                                                                                                }
                                                                                              } else {
                                                                                                result = await createRentalRequestWithPromo();
                                                                                                if (result == 'logout') {
                                                                                                  navigateLogout();
                                                                                                }
                                                                                              }
                                                                                            }
                                                                                          }
                                                                                          if (result == 'success') {
                                                                                            timer();
                                                                                          }
                                                                                          if (destinationLocation != null) {
                                                                                            FirebaseDatabase.instance.ref('requests/${userRequestData['id']}').update({
                                                                                              'destination_location': {
                                                                                                'lat': destinationLocation!.latitude,
                                                                                                'lng': destinationLocation!.longitude
                                                                                              }
                                                                                            });
                                                                                          }
                                                                                          setState(() {
                                                                                            _isLoading = false;
                                                                                          });
                                                                                        } else {
                                                                                          setState(() {
                                                                                            islowwalletbalance = true;
                                                                                          });
                                                                                        }
                                                                                      }
                                                                                    },
                                                                                    text: languages[choosenLanguage]['text_book_now']),
                                                                                ),
                                                                                (userDetails['show_ride_later_feature'] == true)
                                                                                    ? InkWell(
                                                                                        onTap: () async {
                                                                                          if (choosenVehicle != null) {
                                                                                            setState(() {
                                                                                              choosenDateTime = DateTime.now().add(const Duration(minutes: 30));
                                                                                              _dateTimePicker = true;
                                                                                            });
                                                                                          }
                                                                                        },
                                                                                        child: Container(
                                                                                          width: media.width * 0.18,
                                                                                          height: media.width * 0.12,
                                                                                          decoration: BoxDecoration(
                                                                                            borderRadius: BorderRadius.circular(16),
                                                                                            border: Border.all(
                                                                                                color: darkModeBorderColor.withAlpha(
                                                                                              100,
                                                                                            )),
                                                                                          ),
                                                                                          child: Icon(
                                                                                            Icons.date_range_outlined,
                                                                                            color: white,
                                                                                            size: Responsive.width(8, context),
                                                                                          ),
                                                                                        ),
                                                                                      )
                                                                                    // ? Button(

                                                                                    //     color: page,
                                                                                    //     borcolor:
                                                                                    //         darkModeBorderColor
                                                                                    //             .withAlpha(
                                                                                    //                 100),
                                                                                    //     textcolor:
                                                                                    //         buttonColor,
                                                                                    //     width:
                                                                                    //         media.width *
                                                                                    //             0.24,
                                                                                    //     onTap: () async {
                                                                                    //       if (choosenVehicle !=
                                                                                    //           null) {
                                                                                    //         setState(() {
                                                                                    //           choosenDateTime = DateTime
                                                                                    //                   .now()
                                                                                    //               .add(const Duration(
                                                                                    //                   minutes:
                                                                                    //                       30));
                                                                                    //           _dateTimePicker =
                                                                                    //               true;
                                                                                    //         });
                                                                                    //       }
                                                                                    //     },

                                                                                    //     text: languages[
                                                                                    //             choosenLanguage]
                                                                                    //         [
                                                                                    //         'text_ridelater'])
                                                                                    : Container(),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                                Responsive.height(0, context),
                                                                          )
                                                                        ],
                                                                      )
                                                                    ],
                                                                  )
                                                                : Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .start,
                                                                    children: [
                                                                      Text(
                                                                        rentalOption[_showInfoInt]
                                                                            [
                                                                            'name'],
                                                                        style: GoogleFonts.inter(
                                                                            fontSize: media.width *
                                                                                sixteen,
                                                                            color:
                                                                                textColor,
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.025,
                                                                      ),
                                                                      Text(
                                                                        rentalOption[_showInfoInt]
                                                                            [
                                                                            'description'],
                                                                        style: GoogleFonts
                                                                            .inter(
                                                                          fontSize:
                                                                              media.width * fourteen,
                                                                          color:
                                                                              textColor,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              media.width * 0.05),
                                                                      Text(
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_supported_vehicles'],
                                                                        style: GoogleFonts.inter(
                                                                            fontSize: media.width *
                                                                                sixteen,
                                                                            color:
                                                                                textColor,
                                                                            fontWeight:
                                                                                FontWeight.w600),
                                                                      ),
                                                                      SizedBox(
                                                                        height: media.width *
                                                                            0.025,
                                                                      ),
                                                                      Text(
                                                                        rentalOption[_showInfoInt]
                                                                            [
                                                                            'supported_vehicles'],
                                                                        style: GoogleFonts
                                                                            .inter(
                                                                          fontSize:
                                                                              media.width * fourteen,
                                                                          color:
                                                                              textColor,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                          height:
                                                                              media.width * 0.05),
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Text(
                                                                            languages[choosenLanguage]['text_estimated_amount'],
                                                                            style: GoogleFonts.inter(
                                                                                fontSize: media.width * sixteen,
                                                                                color: textColor,
                                                                                fontWeight: FontWeight.w600),
                                                                          ),
                                                                          (rentalOption[_showInfoInt]['has_discount'] != true)
                                                                              ? Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                  children: [
                                                                                    Text(
                                                                                      rentalOption[_showInfoInt]['currency'] + ' ' + rentalOption[_showInfoInt]['fare_amount'].toStringAsFixed(0),
                                                                                      style: GoogleFonts.inter(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                  ],
                                                                                )
                                                                              : Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                                                  children: [
                                                                                    Text(
                                                                                      rentalOption[_showInfoInt]['currency'],
                                                                                      style: GoogleFonts.inter(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                    Text(
                                                                                      ' ${rentalOption[_showInfoInt]['fare_amount'].toStringAsFixed(0)}',
                                                                                      style: GoogleFonts.inter(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600, decoration: TextDecoration.lineThrough),
                                                                                    ),
                                                                                    Text(
                                                                                      ' ${rentalOption[_showInfoInt]['discounted_totel'].toStringAsFixed(0)}',
                                                                                      style: GoogleFonts.inter(fontSize: media.width * fourteen, color: textColor, fontWeight: FontWeight.w600),
                                                                                    ),
                                                                                  ],
                                                                                )
                                                                        ],
                                                                      )
                                                                    ],
                                                                  ),
                                                      );
                                                    }),
                                                    Positioned(
                                                      top: 10,
                                                      right: 10,
                                                      child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _showInfo = false;
                                                            _showInfoInt = null;
                                                          });
                                                        },
                                                        child: Container(
                                                          height:
                                                              media.width * 0.1,
                                                          width:
                                                              media.width * 0.1,
                                                          decoration:
                                                              BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: page),
                                                          child: const Icon(
                                                              Icons.cancel),
                                                        ),
                                                      ),
                                                    ),
                                                    Positioned(
                                                        right: 0,
                                                        top: Responsive.height(
                                                            15, context),
                                                        child: Image(
                                                            fit: BoxFit.fill,
                                                            width: Responsive
                                                                .width(55,
                                                                    context),
                                                            height: Responsive
                                                                .height(25,
                                                                    context),
                                                            image: AssetImage(
                                                              'assets/images/car_info_bg.png',
                                                            ))),
                                                    // Positioned(
                                                    //     right: 0,
                                                    //     child: Image(
                                                    //         width: Responsive
                                                    //             .width(45,
                                                    //                 context),
                                                    //         height: Responsive
                                                    //             .height(15,
                                                    //                 context),
                                                    //         image: NetworkImage(
                                                    //            etaDetails[i]['icon'])))
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                      ),
                                  )
                                : Container(),

                                  //no driver found
                                  (noDriverFound == true)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(
                                                                12))),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: media.width * 0.18,
                                                  width: media.width * 0.18,
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                              0xffFEF2F2)),
                                                  alignment: Alignment.center,
                                                  child: Container(
                                                    height: media.width * 0.14,
                                                    width: media.width * 0.14,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xffFF0000)),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Text(
                                                  languages[choosenLanguage]['text_nodriver'] ?? 'Aucun chauffeur trouvé',
                                                  style: GoogleFonts.inter(
                                                      fontSize: media.width *
                                                          eighteen,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: textColor),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () {
                                                      setState(() {
                                                        noDriverFound = false;
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_tryagain'])
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //internal server error
                                  (tripReqError == true)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(
                                                                12))),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: media.width * 0.18,
                                                  width: media.width * 0.18,
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                              0xffFEF2F2)),
                                                  alignment: Alignment.center,
                                                  child: Container(
                                                    height: media.width * 0.14,
                                                    width: media.width * 0.14,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xffFF0000)),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                SizedBox(
                                                  width: media.width * 0.8,
                                                  child: Text(
                                                      languages[choosenLanguage]?['text_internal_server_error'] ?? 'Server Error',
                                                      style: GoogleFonts.inter(
                                                          fontSize:
                                                              media.width *
                                                                  eighteen,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: textColor),
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () {
                                                      setState(() {
                                                        tripReqError = false;
                                                      });
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_tryagain'])
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //service not available

                                  (serviceNotAvailable)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            decoration: BoxDecoration(
                                                color: page,
                                                borderRadius:
                                                    const BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(12),
                                                        topRight:
                                                            Radius.circular(
                                                                12))),
                                            child: Column(
                                              children: [
                                                Container(
                                                  height: media.width * 0.18,
                                                  width: media.width * 0.18,
                                                  decoration:
                                                      const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Color(
                                                              0xffFEF2F2)),
                                                  alignment: Alignment.center,
                                                  child: Container(
                                                    height: media.width * 0.14,
                                                    width: media.width * 0.14,
                                                    decoration:
                                                        const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Color(
                                                                0xffFF0000)),
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                SizedBox(
                                                  width: media.width * 0.8,
                                                  child: Text(
                                                      languages[choosenLanguage]
                                                          ['text_no_service'],
                                                      style: GoogleFonts.inter(
                                                          fontSize:
                                                              media.width *
                                                                  eighteen,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: textColor),
                                                      textAlign:
                                                          TextAlign.center),
                                                ),
                                                SizedBox(
                                                  height: media.width * 0.05,
                                                ),
                                                Button(
                                                    onTap: () async {
                                                      setState(() {
                                                        serviceNotAvailable =
                                                            false;
                                                      });
                                                      if (widget.type != 1) {
                                                        var val =
                                                            await etaRequest();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                      } else {
                                                        var val =
                                                            await rentalEta();
                                                        if (val == 'logout') {
                                                          navigateLogout();
                                                        }
                                                      }
                                                      setState(() {});
                                                    },
                                                    text: languages[
                                                            choosenLanguage]
                                                        ['text_tryagain'])
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //islowwallet balance popup
                                  (islowwalletbalance == true)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                            width: media.width * 1,
                                            height: media.height * 1,
                                            color:
                                                Colors.black.withOpacity(0.4),
                                            padding: EdgeInsets.all(
                                                media.width * 0.05),
                                            alignment: Alignment.center,
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: media.width * 0.9,
                                                  height: media.height * 0.2,
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  decoration: BoxDecoration(
                                                      color:
                                                          darkModeDialogColor,
                                                      border: Border.all(
                                                          color:
                                                              white.withOpacity(
                                                                  0.3)),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              30)),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                3, context),
                                                      ),
                                                      Text(
                                                          languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_wallet_balance_low'],
                                                          style: GoogleFonts.inter(
                                                              fontSize:
                                                                  media.width *
                                                                      sixteen,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              color: textColor),
                                                          textAlign:
                                                              TextAlign.center),
                                                      SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                2, context),
                                                      ),
                                                      Button(
                                                          width:
                                                              media.width * 0.9,
                                                          height:
                                                              media.width * 0.1,
                                                          onTap: () {
                                                            setState(() {
                                                              islowwalletbalance =
                                                                  false;
                                                            });
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_ok'])
                                                    ],
                                                  ),
                                                ),
                                                Positioned(
                                                    top: 15,
                                                    right: 15,
                                                    child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            islowwalletbalance =
                                                                false;
                                                          });
                                                        },
                                                        child: Icon(
                                                          Icons.cancel,
                                                          color: white,
                                                        )))
                                              ],
                                            ),
                                          ))
                                      : Container(),
                                  //choose payment method
                                  (_choosePayment == true)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Scaffold(
                                              backgroundColor:
                                                  Colors.transparent,
                                              body: SingleChildScrollView(
                                                physics:
                                                    const BouncingScrollPhysics(),
                                                child: SizedBox(
                                                  height: media.height * 1,
                                                  width: media.width * 1,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.9,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .end,
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  _choosePayment =
                                                                      false;
                                                                  promoKey
                                                                      .clear();
                                                                });
                                                              },
                                                              child: Container(
                                                                height: media
                                                                        .width *
                                                                    0.1,
                                                                width: media
                                                                        .width *
                                                                    0.1,
                                                                decoration: BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color:
                                                                        page),
                                                                child: const Icon(
                                                                    Icons
                                                                        .cancel_outlined),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Container(
                                                        width:
                                                            media.width * 0.9,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: page,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        padding: EdgeInsets.all(
                                                            media.width * 0.05),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_paymentmethod'],
                                                              style: GoogleFonts.inter(
                                                                  fontSize: media
                                                                          .width *
                                                                      twenty,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      textColor),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.015,
                                                            ),
                                                            Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_choose_paynoworlater'],
                                                              style: GoogleFonts.inter(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      textColor),
                                                            ),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.015,
                                                            ),
                                                            (widget.type != 1)
                                                                ? Column(
                                                                    children: etaDetails[choosenVehicle]
                                                                            [
                                                                            'payment_type']
                                                                        .toString()
                                                                        .split(
                                                                            ',')
                                                                        .toList()
                                                                        .asMap()
                                                                        .map((i,
                                                                            value) {
                                                                          return MapEntry(
                                                                              i,
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    payingVia = i;
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  padding: EdgeInsets.all(media.width * 0.02),
                                                                                  width: media.width * 0.9,
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Row(
                                                                                        children: [
                                                                                          SizedBox(
                                                                                            width: media.width * 0.06,
                                                                                            child: (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                                ? Image.asset(
                                                                                                    'assets/images/cash.png',
                                                                                                    fit: BoxFit.contain,
                                                                                                  )
                                                                                                : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                    ? Image.asset(
                                                                                                        'assets/images/wallet.png',
                                                                                                        fit: BoxFit.contain,
                                                                                                      )
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                        ? Image.asset(
                                                                                                            'assets/images/card.png',
                                                                                                            fit: BoxFit.contain,
                                                                                                          )
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                            ? Image.asset(
                                                                                                                'assets/images/upi.png',
                                                                                                                fit: BoxFit.contain,
                                                                                                              )
                                                                                                            : Container(),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.05,
                                                                                          ),
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Text(
                                                                                                etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i].toString(),
                                                                                                style: GoogleFonts.inter(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                              ),
                                                                                              Text(
                                                                                                (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                                    ? languages[choosenLanguage]['text_paycash']
                                                                                                    : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                        ? languages[choosenLanguage]['text_paywallet']
                                                                                                        : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                            ? languages[choosenLanguage]['text_paycard']
                                                                                                            : (etaDetails[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                                ? languages[choosenLanguage]['text_payupi']
                                                                                                                : '',
                                                                                                style: GoogleFonts.inter(
                                                                                                  fontSize: media.width * ten,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                          Expanded(
                                                                                              child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                                                            children: [
                                                                                              Container(
                                                                                                height: media.width * 0.05,
                                                                                                width: media.width * 0.05,
                                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: page, border: Border.all(color: Colors.black, width: 1.2)),
                                                                                                alignment: Alignment.center,
                                                                                                child: (payingVia == i) ? Container(height: media.width * 0.03, width: media.width * 0.03, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)) : Container(),
                                                                                              )
                                                                                            ],
                                                                                          ))
                                                                                        ],
                                                                                      )
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ));
                                                                        })
                                                                        .values
                                                                        .toList(),
                                                                  )
                                                                : Column(
                                                                    children: rentalOption[choosenVehicle]
                                                                            [
                                                                            'payment_type']
                                                                        .toString()
                                                                        .split(
                                                                            ',')
                                                                        .toList()
                                                                        .asMap()
                                                                        .map((i,
                                                                            value) {
                                                                          return MapEntry(
                                                                              i,
                                                                              InkWell(
                                                                                onTap: () {
                                                                                  setState(() {
                                                                                    payingVia = i;
                                                                                  });
                                                                                },
                                                                                child: Container(
                                                                                  padding: EdgeInsets.all(media.width * 0.02),
                                                                                  width: media.width * 0.9,
                                                                                  child: Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                    children: [
                                                                                      Row(
                                                                                        children: [
                                                                                          SizedBox(
                                                                                            width: media.width * 0.06,
                                                                                            child: (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                                ? Image.asset(
                                                                                                    'assets/images/cash.png',
                                                                                                    fit: BoxFit.contain,
                                                                                                  )
                                                                                                : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                    ? Image.asset(
                                                                                                        'assets/images/wallet.png',
                                                                                                        fit: BoxFit.contain,
                                                                                                      )
                                                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                        ? Image.asset(
                                                                                                            'assets/images/card.png',
                                                                                                            fit: BoxFit.contain,
                                                                                                          )
                                                                                                        : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                            ? Image.asset(
                                                                                                                'assets/images/upi.png',
                                                                                                                fit: BoxFit.contain,
                                                                                                              )
                                                                                                            : Container(),
                                                                                          ),
                                                                                          SizedBox(
                                                                                            width: media.width * 0.05,
                                                                                          ),
                                                                                          Column(
                                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                                            children: [
                                                                                              Text(
                                                                                                rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i].toString(),
                                                                                                style: GoogleFonts.inter(fontSize: media.width * fourteen, fontWeight: FontWeight.w600),
                                                                                              ),
                                                                                              Text(
                                                                                                (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'cash')
                                                                                                    ? languages[choosenLanguage]['text_paycash']
                                                                                                    : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'wallet')
                                                                                                        ? languages[choosenLanguage]['text_paywallet']
                                                                                                        : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'card')
                                                                                                            ? languages[choosenLanguage]['text_paycard']
                                                                                                            : (rentalOption[choosenVehicle]['payment_type'].toString().split(',').toList()[i] == 'upi')
                                                                                                                ? languages[choosenLanguage]['text_payupi']
                                                                                                                : '',
                                                                                                style: GoogleFonts.inter(
                                                                                                  fontSize: media.width * ten,
                                                                                                ),
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                          Expanded(
                                                                                              child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.end,
                                                                                            children: [
                                                                                              Container(
                                                                                                height: media.width * 0.05,
                                                                                                width: media.width * 0.05,
                                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: page, border: Border.all(color: Colors.black, width: 1.2)),
                                                                                                alignment: Alignment.center,
                                                                                                child: (payingVia == i) ? Container(height: media.width * 0.03, width: media.width * 0.03, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)) : Container(),
                                                                                              )
                                                                                            ],
                                                                                          ))
                                                                                        ],
                                                                                      )
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              ));
                                                                        })
                                                                        .values
                                                                        .toList(),
                                                                  ),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.02,
                                                            ),
                                                            Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                                border: Border.all(
                                                                    color:
                                                                        borderLines,
                                                                    width: 1.2),
                                                              ),
                                                              padding: EdgeInsets
                                                                  .fromLTRB(
                                                                      media.width *
                                                                          0.025,
                                                                      0,
                                                                      media.width *
                                                                          0.025,
                                                                      0),
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              child: Row(
                                                                children: [
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.06,
                                                                    child: Image.asset(
                                                                        'assets/images/promocode.png',
                                                                        fit: BoxFit
                                                                            .contain),
                                                                  ),
                                                                  SizedBox(
                                                                    width: media
                                                                            .width *
                                                                        0.05,
                                                                  ),
                                                                  Expanded(
                                                                    child: (promoStatus ==
                                                                            null)
                                                                        ? TextField(
                                                                            controller:
                                                                                promoKey,
                                                                            onChanged:
                                                                                (val) {
                                                                              setState(() {
                                                                                promoCode = val;
                                                                              });
                                                                            },
                                                                            decoration: InputDecoration(
                                                                                border: InputBorder.none,
                                                                                hintText: languages[choosenLanguage]['text_enterpromo'],
                                                                                hintStyle: GoogleFonts.inter(fontSize: media.width * twelve, color: hintColor)),
                                                                          )
                                                                        : (promoStatus ==
                                                                                1)
                                                                            ? Container(
                                                                                padding: EdgeInsets.fromLTRB(0, media.width * 0.045, 0, media.width * 0.045),
                                                                                child: Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Column(
                                                                                      children: [
                                                                                        Text(promoKey.text, style: GoogleFonts.inter(fontSize: media.width * ten, color: const Color(0xff319900))),
                                                                                        Text(languages[choosenLanguage]['text_promoaccepted'], style: GoogleFonts.inter(fontSize: media.width * ten, color: const Color(0xff319900))),
                                                                                      ],
                                                                                    ),
                                                                                    InkWell(
                                                                                      onTap: () async {
                                                                                        setState(() {
                                                                                          _isLoading = true;
                                                                                        });
                                                                                        dynamic result;
                                                                                        if (widget.type != 1) {
                                                                                          result = await etaRequest();
                                                                                        } else {
                                                                                          result = await rentalEta();
                                                                                        }
                                                                                        setState(() {
                                                                                          _isLoading = false;
                                                                                          if (result == true) {
                                                                                            promoStatus = null;
                                                                                            promoCode = '';
                                                                                          } else if (result == 'logout') {
                                                                                            navigateLogout();
                                                                                          }
                                                                                        });
                                                                                      },
                                                                                      child: Text(languages[choosenLanguage]['text_remove'], style: GoogleFonts.inter(fontSize: media.width * twelve, color: const Color(0xff319900))),
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                              )
                                                                            : (promoStatus == 2)
                                                                                ? Container(
                                                                                    padding: EdgeInsets.fromLTRB(0, media.width * 0.045, 0, media.width * 0.045),
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                      children: [
                                                                                        Text(promoKey.text, style: GoogleFonts.inter(fontSize: media.width * twelve, color: const Color(0xffFF0000))),
                                                                                        InkWell(
                                                                                          onTap: () async {
                                                                                            setState(() {
                                                                                              promoStatus = null;
                                                                                              promoCode = '';
                                                                                              promoKey.clear();
                                                                                            });
                                                                                            dynamic val;
                                                                                            // promoKey.text = promoCode;
                                                                                            if (widget.type != 1) {
                                                                                              val = await etaRequest();
                                                                                            } else {
                                                                                              val = await rentalEta();
                                                                                            }
                                                                                            if (val == 'logout') {
                                                                                              navigateLogout();
                                                                                            }
                                                                                            setState(() {});
                                                                                          },
                                                                                          child: Text(languages[choosenLanguage]['text_remove'], style: GoogleFonts.inter(fontSize: media.width * twelve, color: const Color(0xffFF0000))),
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                  )
                                                                                : Container(),
                                                                  )
                                                                ],
                                                              ),
                                                            ),

                                                            //promo code status
                                                            (promoStatus == 2)
                                                                ? Container(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    alignment:
                                                                        Alignment
                                                                            .center,
                                                                    padding: EdgeInsets.only(
                                                                        top: media.height *
                                                                            0.02),
                                                                    child: Text(
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_promorejected'],
                                                                        style: GoogleFonts.inter(
                                                                            fontSize: media.width *
                                                                                ten,
                                                                            color:
                                                                                const Color(0xffFF0000))),
                                                                  )
                                                                : Container(),
                                                            SizedBox(
                                                              height:
                                                                  media.height *
                                                                      0.02,
                                                            ),
                                                            Button(
                                                                onTap:
                                                                    () async {
                                                                  if (promoCode ==
                                                                      '') {
                                                                    setState(
                                                                        () {
                                                                      _choosePayment =
                                                                          false;
                                                                    });
                                                                  } else {
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          true;
                                                                    });
                                                                    dynamic val;
                                                                    if (widget
                                                                            .type !=
                                                                        1) {
                                                                      val =
                                                                          await etaRequestWithPromo();
                                                                    } else {
                                                                      val =
                                                                          await rentalRequestWithPromo();
                                                                    }
                                                                    if (val ==
                                                                        'logout') {
                                                                      navigateLogout();
                                                                    }
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          false;
                                                                    });
                                                                  }
                                                                },
                                                                text: languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_confirm'])
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ))
                                      : Container(),

                                  //bottom nav bar after request accepted
                                  Visibility(
                                    visible: false,
                                    child:
                                        (userRequestData['accepted_at'] != null)
                                            ? Positioned(
                                                top: MediaQuery.of(context)
                                                        .padding
                                                        .top +
                                                    25,
                                                child: Container(
                                                  padding: EdgeInsets.fromLTRB(
                                                      media.width * 0.05,
                                                      media.width * 0.025,
                                                      media.width * 0.05,
                                                      media.width * 0.025),
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      boxShadow: [
                                                        BoxShadow(
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2),
                                                            spreadRadius: 2)
                                                      ],
                                                      color: page),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        height: 10,
                                                        width: 10,
                                                        decoration:
                                                            BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                      blurRadius:
                                                                          2,
                                                                      color: Colors
                                                                          .black
                                                                          .withOpacity(
                                                                              0.2),
                                                                      spreadRadius:
                                                                          2)
                                                                ],
                                                                color: (userRequestData['accepted_at'] !=
                                                                            null &&
                                                                        userRequestData['arrived_at'] ==
                                                                            null)
                                                                    ? const Color(
                                                                        0xff2E67D5)
                                                                    : (userRequestData['accepted_at'] != null &&
                                                                            userRequestData['arrived_at'] !=
                                                                                null &&
                                                                            userRequestData['is_trip_start'] ==
                                                                                0)
                                                                        ? const Color(
                                                                            0xff319900)
                                                                        : (userRequestData['accepted_at'] != null &&
                                                                                userRequestData['arrived_at'] != null &&
                                                                                userRequestData['is_trip_start'] != 0)
                                                                            ? const Color(0xffFF0000)
                                                                            : Colors.transparent),
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            media.width * 0.02,
                                                      ),
                                                      Text(
                                                          (userRequestData[
                                                                          'accepted_at'] !=
                                                                      null &&
                                                                  userRequestData['arrived_at'] ==
                                                                      null &&
                                                                  _dist != null)
                                                              ? (languages[choosenLanguage]['text_arrive_eta'] ?? 'ETA') +
                                                              ' ' +
                                                              double.parse(((_dist * 2)).toString())
                                                                  .round()
                                                                  .toString() +
                                                              ' ' +
                                                              (languages[choosenLanguage]['text_mins'] ?? 'min')
                                                              : (userRequestData['accepted_at'] !=
                                                                          null &&
                                                                      userRequestData['arrived_at'] !=
                                                                          null &&
                                                                      userRequestData['is_trip_start'] ==
                                                                          0)
                                                                  ? languages[
                                                                          choosenLanguage][
                                                                      'text_arrived']
                                                                  : (userRequestData['accepted_at'] != null &&
                                                                          userRequestData['arrived_at'] !=
                                                                              null &&
                                                                          userRequestData['is_trip_start'] !=
                                                                              null)
                                                                      ? (_dist !=
                                                                              null)
                                                                          ? languages[choosenLanguage]['text_onride_min'] +
                                                                              ' ' +
                                                                              double.parse(((_dist * 2)).toString()).round().toString() +
                                                                              'mins'
                                                                          : languages[choosenLanguage]['text_onride']
                                                                      : '',
                                                          style: GoogleFonts.inter(
                                                            fontSize:
                                                                media.width *
                                                                    twelve,
                                                            color: (userRequestData['accepted_at'] !=
                                                                        null &&
                                                                    userRequestData[
                                                                            'arrived_at'] ==
                                                                        null)
                                                                ? const Color(
                                                                    0xff2E67D5)
                                                                : (userRequestData['accepted_at'] != null &&
                                                                        userRequestData[
                                                                                'arrived_at'] !=
                                                                            null &&
                                                                        userRequestData[
                                                                                'is_trip_start'] ==
                                                                            0)
                                                                    ? const Color(
                                                                        0xff319900)
                                                                    : (userRequestData['accepted_at'] != null &&
                                                                            userRequestData['arrived_at'] !=
                                                                                null &&
                                                                            userRequestData['is_trip_start'] ==
                                                                                1)
                                                                        ? const Color(
                                                                            0xffFF0000)
                                                                        : Colors
                                                                            .transparent,
                                                          ))
                                                    ],
                                                  ),
                                                ))
                                            : Container(),
                                  ),
                                  (userRequestData.isNotEmpty &&
                                              userRequestData['is_later'] ==
                                                  null &&
                                              userRequestData['accepted_at'] ==
                                                  null ||
                                          userRequestData.isNotEmpty &&
                                              userRequestData['is_later'] ==
                                                  0 &&
                                              userRequestData['accepted_at'] ==
                                                  null)
                                      ? Positioned(
                                          bottom: 0,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            alignment: Alignment.topCenter,
                                            children: [
                                              Container(
                                                width: media.width * 1,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      const BorderRadius.only(
                                                          topLeft:
                                                              Radius.circular(
                                                                  30),
                                                          topRight:
                                                              Radius.circular(
                                                                  30)),
                                                  color: darkModeDialogColor,
                                                ),
                                                padding: EdgeInsets.all(
                                                    media.width * 0.05),
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                      height: Responsive.height(
                                                          4, context),
                                                    ),
                                                    SizedBox(
                                                      width: media.width * 0.9,
                                                      child: MyText(
                                                        color:
                                                            Color(0xff929292),
                                                        text: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_search_captain'],
                                                        size: 16,
                                                        fontweight:
                                                            FontWeight.w400,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.015,
                                                    ),
                                                    Container(
                                                      width: media.width * 0.9,
                                                      height: 1,
                                                      color: white
                                                          .withOpacity(0.3),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.015,
                                                    ),
                                                    MyText(
                                                      text: languages[
                                                              choosenLanguage][
                                                          'text_finddriverdesc'],
                                                      size: 14,
                                                      fontweight:
                                                          FontWeight.w300,
                                                      // textAlign: TextAlign.center,
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.02,
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.width * 0.35,
                                                      child: lottile.Lottie.asset(
                                                        'assets/images/driver_search.json',
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          media.height * 0.03,
                                                    ),
                                                    Button(
                                                        width:
                                                            media.width * 0.9,
                                                        color:
                                                            darkModeSecContainer,
                                                        borcolor: white
                                                            .withOpacity(0.15),
                                                        textcolor:
                                                            Color(0xff929292),
                                                        onTap: () async {
                                                          timers?.cancel();
                                                          timers = null;
                                                          timing = null;
                                                          _driverStream = null;
                                                          _lastDriverId = null;
                                                          var val = await cancelRequest();
                                                          userRequestData = {};
                                                          valueNotifierBook.incrementNotifier();
                                                          if (mounted) {
                                                            setState(() {
                                                              cancelRequestByUser = true;
                                                            });
                                                          }
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          }
                                                        },
                                                        text: languages[
                                                                choosenLanguage]
                                                            ['text_cancel']),
                                                    ButtonBottomSpace()
                                                  ],
                                                ),
                                              ),
                                              Positioned(
                                                top: -Responsive.height(
                                                    2.4, context),
                                                child: Container(
                                                    clipBehavior:
                                                        Clip.antiAlias,
                                                    height: media.width * 0.12,
                                                    width: media.width * 0.37,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(media
                                                                    .width),
                                                        color:
                                                            darkModeSecContainer),
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: SizedBox(
                                                      height:
                                                          media.width * 0.12,
                                                      width:
                                                          (media.width * 0.37),
                                                      child: Stack(
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.width *
                                                                    0.12,
                                                            width: (media
                                                                    .width *
                                                                0.37 *
                                                                (timing /
                                                                    userDetails[
                                                                        'maximum_time_for_find_drivers_for_regular_ride'])),
                                                            decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.only(
                                                                    topLeft: Radius
                                                                        .circular(media
                                                                            .width),
                                                                    bottomLeft:
                                                                        Radius.circular(media
                                                                            .width)),
                                                                color:
                                                                    buttonColor),
                                                          ),
                                                          Container(
                                                            alignment: Alignment
                                                                .center,
                                                            height:
                                                                media.width *
                                                                    0.12,
                                                            width:
                                                                (media.width *
                                                                    0.37),
                                                            child: (timing !=
                                                                    null)
                                                                ? Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .center,
                                                                    children: [
                                                                      Icon(
                                                                        Icons
                                                                            .access_time_filled,
                                                                        size:
                                                                            20,
                                                                      ),
                                                                      SizedBox(
                                                                        width:
                                                                            6,
                                                                      ),
                                                                      Text(
                                                                        '${Duration(seconds: timing ?? 0).toString().substring(3, 7)}',
                                                                        style: GoogleFonts.inter(
                                                                            fontSize:
                                                                                17,
                                                                            color:
                                                                                white),
                                                                      ),
                                                                    ],
                                                                  )
                                                                : Container(),
                                                          )
                                                        ],
                                                      ),
                                                    )),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Container(),
                                  (userRequestData.isNotEmpty &&
                                          userRequestData['accepted_at'] !=
                                              null)
                                      ? Positioned(
                                          bottom: 0,
                                          child: GestureDetector(
                                            onVerticalDragStart: (v) {
                                              start = v.globalPosition.dy;
                                              gesture.clear();
                                            },
                                            onVerticalDragUpdate: (v) {
                                              gesture.add(v.globalPosition.dy);
                                            },
                                            onVerticalDragEnd: (v) {
                                              if (gesture.isNotEmpty &&
                                                  start >
                                                      gesture[
                                                          gesture.length - 1] &&
                                                  _ontripBottom == false) {
                                                setState(() {
                                                  _ontripBottom = true;
                                                });
                                              } else if (gesture.isNotEmpty &&
                                                  start <
                                                      gesture[
                                                          gesture.length - 1] &&
                                                  _ontripBottom == true) {
                                                setState(() {
                                                  _ontripBottom = false;
                                                });
                                              }
                                            },
                                            child: Container(
                                                padding: EdgeInsets.fromLTRB(
                                                    media.width * 0.05,
                                                    0,
                                                    media.width * 0.05,
                                                    media.width * 0.05),
                                                width: media.width * 1,
                                                // height: _ontripBottom == true?media.height*0.9:media.height*0.5,
                                                decoration: BoxDecoration(
                                                    color: darkModeDialogColor,
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    30),
                                                            topRight:
                                                                Radius.circular(
                                                                    30))),
                                                child: SingleChildScrollView(
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Center(
                                                        child: Container(
                                                            margin:
                                                                EdgeInsets.only(
                                                                    top: 7),
                                                            width: Responsive
                                                                .width(36,
                                                                    context),
                                                            height: 5,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Color(
                                                                  0xff525252),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          3.5),
                                                            )),
                                                      ),
                                                      SizedBox(
                                                          child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            flex: 8,
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                top: 8,
                                                              ),
                                                              child: MyText(
                                                                text: (userRequestData['accepted_at'] !=
                                                                            null &&
                                                                        userRequestData['arrived_at'] ==
                                                                            null)
                                                                    ? languages[
                                                                            choosenLanguage]
                                                                        [
                                                                        'text_driver_nearby']
                                                                    : (userRequestData['accepted_at'] != null &&
                                                                            userRequestData['arrived_at'] !=
                                                                                null &&
                                                                            userRequestData['is_trip_start'] ==
                                                                                0)
                                                                        ? languages[choosenLanguage]
                                                                            [
                                                                            'text_captain_wait']
                                                                        : (userRequestData['accepted_at'] != null &&
                                                                                userRequestData['arrived_at'] != null &&
                                                                                userRequestData['is_trip_start'] == 1)
                                                                            ? languages[choosenLanguage]['text_onride']
                                                                            : '',
                                                                size: media
                                                                        .width *
                                                                    0.055,
                                                                fontweight:
                                                                    FontWeight
                                                                        .w600,
                                                                maxLines: 1,
                                                              ),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            flex: 4,
                                                            child: SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.4,
                                                              child: (userRequestData[
                                                                              'is_trip_start'] !=
                                                                          1 &&
                                                                      userRequestData[
                                                                              'show_otp_feature'] ==
                                                                          true)
                                                                  ? MyText(
                                                                      text:
                                                                          'Otp : ${userRequestData['ride_otp']}',
                                                                      size: media
                                                                              .width *
                                                                          fourteen,
                                                                      textAlign:
                                                                          TextAlign
                                                                              .end,
                                                                      fontweight:
                                                                          FontWeight
                                                                              .bold,
                                                                      maxLines:
                                                                          1,
                                                                    )
                                                                  : Container(),
                                                            ),
                                                          )
                                                        ],
                                                      )),
                                                      SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                2, context),
                                                      ),
                                                      Container(
                                                        width: Responsive.width(
                                                            90, context),
                                                        height: 1,
                                                        color: white
                                                            .withOpacity(0.3),
                                                      ),
                                                      if ((userRequestData[
                                                              'is_trip_start'] !=
                                                          1))
                                                        Container(
                                                          margin: EdgeInsets.only(
                                                              top: media.width *
                                                                  0.03),
                                                          color: (isDarkTheme ==
                                                                  true)
                                                              ? darkModeDialogColor
                                                              : const Color(
                                                                  0xffF3F3F3),
                                                          child: Row(
                                                            children: [
                                                              SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.8,
                                                                child: MyText(
                                                                    text: (userRequestData['accepted_at'] !=
                                                                                null &&
                                                                            userRequestData['arrived_at'] ==
                                                                                null)
                                                                        ? languages[choosenLanguage]['text_captain_nearby_desc'].replaceAll(
                                                                            '2',
                                                                            (_dist != null)
                                                                                ? double.parse(((_dist * 2)).toString())
                                                                                    .round()
                                                                                    .toString()
                                                                                : '-')
                                                                        : languages[choosenLanguage]['text_captain_arrived_desc'].replaceAll(
                                                                            '3',
                                                                            userRequestData['free_waiting_time_in_mins_before_trip_start']
                                                                                .toString()),
                                                                    size: 14,
                                                                    fontweight:
                                                                        FontWeight
                                                                            .w300,
                                                                    color:
                                                                        white),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      SizedBox(
                                                        height:
                                                            media.height * 0.01,
                                                      ),
                                                      MyText(
                                                        text: userRequestData[
                                                                'driverDetail'][
                                                            'data']['car_number'],
                                                        textAlign:
                                                            TextAlign.end,
                                                        size: 16,
                                                        maxLines: 1,
                                                        fontweight:
                                                            FontWeight.w400,
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                3.25, context),
                                                      ),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.width *
                                                                    0.125,
                                                            width: media.width *
                                                                0.125,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                image: DecorationImage(
                                                                    image: NetworkImage(userRequestData['driverDetail']
                                                                            [
                                                                            'data']
                                                                        [
                                                                        'profile_picture']),
                                                                    fit: BoxFit
                                                                        .cover)),
                                                          ),
                                                          SizedBox(
                                                            width: 13,
                                                          ),
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  MyText(
                                                                    text: getFirstName(userRequestData['driverDetail']
                                                                            [
                                                                            'data']
                                                                        [
                                                                        'name']),
                                                                    size: 19,
                                                                    fontweight:
                                                                        FontWeight
                                                                            .w800,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 8,
                                                                  ),
                                                                  Icon(
                                                                    Icons.star,
                                                                    color:
                                                                        buttonColor,
                                                                    size: media
                                                                            .width *
                                                                        0.0425,
                                                                  ),
                                                                  Text(
                                                                    userRequestData['driverDetail']['data']
                                                                            [
                                                                            'rating']
                                                                        .toString(),
                                                                    style: GoogleFonts.inter(
                                                                        fontSize:
                                                                            13,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w400,
                                                                        color:
                                                                            white),
                                                                  ),
                                                                ],
                                                              ),
                                                              MyText(
                                                                text:
                                                                '${userRequestData['driverDetail']['data']['car_make_name']},${userRequestData['driverDetail']['data']['car_model_name']}',
                                                                size: 12,
                                                                maxLines: 1,
                                                                fontweight:
                                                                FontWeight
                                                                    .w400,
                                                                color: Color(
                                                                    0xff929292),
                                                              ),
                                                              SizedBox(height: 3),
                                                              Row(
                                                                children: [
                                                                  Icon(Icons.phone, size: 12, color: Color(0xff929292)),
                                                                  SizedBox(width: 4),
                                                                  MyText(
                                                                    text: userRequestData['driverDetail']['data']['mobile'].toString(),
                                                                    size: 12,
                                                                    fontweight: FontWeight.w400,
                                                                    color: Color(0xff929292),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          Expanded(
                                                            child: userRequestData[
                                                                        'is_trip_start'] !=
                                                                    1
                                                                ? Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .end,
                                                                    children: [
                                                                      InkWell(
                                                                        onTap:
                                                                            () async {
                                                                          var result = await Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(builder: (context) => const ChatPage()));
                                                                          if (result) {
                                                                            setState(() {});
                                                                          }
                                                                        },
                                                                        child:
                                                                            Stack(
                                                                          children: [
                                                                            Container(
                                                                                height: media.width * 0.096,
                                                                                width: media.width * 0.096,
                                                                                decoration: BoxDecoration(color: buttonColor, shape: BoxShape.circle),
                                                                                alignment: Alignment.center,
                                                                                child: Icon(Icons.chat_bubble, size: media.width * 0.05)),
                                                                            if (chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).isNotEmpty)
                                                                              Positioned(
                                                                                  top: media.width * 0.01,
                                                                                  right: media.width * 0.01,
                                                                                  child: Text(
                                                                                    chatList.where((element) => element['from_type'] == 2 && element['seen'] == 0).length.toString(),
                                                                                    style: GoogleFonts.inter(fontSize: media.width * twelve, color: const Color(0xffFF0000)),
                                                                                  ))
                                                                          ],
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.025,
                                                                      ),
                                                                      InkWell(
                                                                        onTap:
                                                                            () {
                                                                          // makingPhoneCall(userRequestData['driverDetail']['data']['mobile']);
                                                                          if (userRequestData['id'] !=
                                                                              null) {
                                                                            Navigator.push(context,
                                                                                MaterialPageRoute(builder: (context) {
                                                                              FirebaseDatabase.instance.ref('requests/${userRequestData['id']}').update({
                                                                                callingStatus: readyForCall
                                                                              });
                                                                              return const CallScreen();
                                                                            }));
                                                                          }
                                                                        },
                                                                        child: Container(
                                                                            height: media.width *
                                                                                0.096,
                                                                            width: media.width *
                                                                                0.096,
                                                                            decoration:
                                                                                BoxDecoration(color: buttonColor, shape: BoxShape.circle),
                                                                            alignment: Alignment.center,
                                                                            child: Icon(Icons.call, size: media.width * 0.06)),
                                                                      )
                                                                    ],
                                                                  )
                                                                : SizedBox(),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                3.5, context),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          (widget.type != 1 &&
                                                                  userRequestData[
                                                                          'drop_address'] !=
                                                                      null)
                                                              ? Row(
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.06,
                                                                          child: (userRequestData['payment_opt'].toString() == '1')
                                                                              ? Image.asset(
                                                                                  'assets/images/cash.png',
                                                                                  fit: BoxFit.contain,
                                                                                )
                                                                              : (userRequestData['payment_opt'].toString() == '2')
                                                                                  ? Image.asset(
                                                                                      'assets/images/wallet.png',
                                                                                      fit: BoxFit.contain,
                                                                                    )
                                                                                  : (userRequestData['payment_opt'].toString() == '0')
                                                                                      ? Image.asset(
                                                                                          'assets/images/card.png',
                                                                                          fit: BoxFit.contain,
                                                                                        )
                                                                                      : Container(),
                                                                        ),
                                                                        SizedBox(
                                                                          width:
                                                                              10,
                                                                        ),
                                                                        MyText(
                                                                            text: userRequestData['payment_type_string']
                                                                                .toString(),
                                                                            size: media.width *
                                                                                sixteen,
                                                                            color:
                                                                                textColor),
                                                                      ],
                                                                    ),
                                                                    SizedBox(
                                                                      width: 10,
                                                                    ),
                                                                    MyText(
                                                                      textAlign:
                                                                          TextAlign
                                                                              .end,
                                                                      text: userRequestData[
                                                                              'requested_currency_symbol'] +
                                                                          ' ' +
                                                                          userRequestData['request_eta_amount']
                                                                              .toStringAsFixed(0),
                                                                      size: media
                                                                              .width *
                                                                          eighteen,
                                                                      color:
                                                                          textColor,
                                                                      maxLines:
                                                                          1,
                                                                    ),
                                                                  ],
                                                                )
                                                              : Container(),
                                                        ],
                                                      ),
                                                      if ((userRequestData[
                                                              'is_trip_start'] ==
                                                          1))
                                                        SizedBox(
                                                          height: media.width *
                                                              0.025,
                                                        ),
                                                      if (_ontripBottom == true)
                                                        SizedBox(
                                                          height: media.width *
                                                              0.05,
                                                        ),
                                                      if (_ontripBottom == true)
                                                        Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  darkModeDialogColor,
                                                              border: Border(
                                                                top:
                                                                    BorderSide(),
                                                              ),
                                                            ),
                                                            width: media.width *
                                                                0.9,
                                                            child: Column(
                                                              children: [
                                                                Container(
                                                                  width: media
                                                                          .width *
                                                                      0.9,
                                                                  height: 1,
                                                                  color: white
                                                                      .withOpacity(
                                                                          0.3),
                                                                ),
                                                                SizedBox(
                                                                  height: Responsive
                                                                      .height(2,
                                                                          context),
                                                                ),
                                                                (userRequestData['is_rental'] !=
                                                                            true &&
                                                                        userRequestData['drop_address'] !=
                                                                            null)
                                                                    ? Container(
                                                                        padding:
                                                                            EdgeInsets.all(media.width *
                                                                                0.03),
                                                                        child:
                                                                            SingleChildScrollView(
                                                                          child:
                                                                              Column(
                                                                            children: [
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                children: [
                                                                                  Container(
                                                                                    height: media.width * 0.04,
                                                                                    width: media.width * 0.04,
                                                                                    alignment: Alignment.center,
                                                                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: buttonColor)),
                                                                                    child: Container(
                                                                                      height: media.width * 0.025,
                                                                                      width: media.width * 0.025,
                                                                                      decoration: BoxDecoration(shape: BoxShape.circle, color: buttonColor),
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.06,
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: MyText(
                                                                                      text: userRequestData['pick_address'],
                                                                                      size: media.width * twelve,
                                                                                      // maxLines: 1,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              SizedBox(
                                                                                height: media.width * 0.035,
                                                                              ),
                                                                              (tripStops.isNotEmpty)
                                                                                  ? Column(
                                                                                      children: tripStops
                                                                                          .asMap()
                                                                                          .map((i, value) {
                                                                                            return MapEntry(
                                                                                                i,
                                                                                                (i < tripStops.length - 1)
                                                                                                    ? Container(
                                                                                                        padding: EdgeInsets.only(top: media.width * 0.02, bottom: media.width * 0.02),
                                                                                                        child: Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.start,
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              height: media.width * 0.06,
                                                                                                              width: media.width * 0.06,
                                                                                                              alignment: Alignment.center,
                                                                                                              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withOpacity(0.1)),
                                                                                                              child: MyText(
                                                                                                                text: (i + 1).toString(),
                                                                                                                // maxLines: 1,
                                                                                                                color: const Color(0xFFFF0000),
                                                                                                                fontweight: FontWeight.w600,
                                                                                                                size: media.width * twelve,
                                                                                                              ),
                                                                                                            ),
                                                                                                            SizedBox(
                                                                                                              width: media.width * 0.05,
                                                                                                            ),
                                                                                                            Expanded(
                                                                                                              child: MyText(
                                                                                                                text: tripStops[i]['address'],
                                                                                                                // maxLines: 1,
                                                                                                                size: media.width * twelve,
                                                                                                              ),
                                                                                                            ),
                                                                                                          ],
                                                                                                        ),
                                                                                                      )
                                                                                                    : Container());
                                                                                          })
                                                                                          .values
                                                                                          .toList(),
                                                                                    )
                                                                                  : Container(),
                                                                              Row(
                                                                                mainAxisAlignment: MainAxisAlignment.start,
                                                                                children: [
                                                                                  Icon(
                                                                                    Icons.location_on_outlined,
                                                                                    size: media.width * 0.05,
                                                                                    color: buttonColor,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.05,
                                                                                  ),
                                                                                  Expanded(
                                                                                    child: MyText(
                                                                                      text: userRequestData['drop_address'],
                                                                                      size: media.width * twelve,
                                                                                      // maxLines: 1,
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      )
                                                                    : Container(
                                                                        height: media.width *
                                                                            0.1,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        padding: EdgeInsets.only(
                                                                            left: media.width *
                                                                                0.05,
                                                                            right:
                                                                                media.width * 0.05),
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.center,
                                                                          children: [
                                                                            Container(
                                                                              height: media.width * 0.05,
                                                                              width: media.width * 0.05,
                                                                              alignment: Alignment.center,
                                                                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.blue),
                                                                              child: Container(
                                                                                height: media.width * 0.025,
                                                                                width: media.width * 0.025,
                                                                                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.8)),
                                                                              ),
                                                                            ),
                                                                            SizedBox(
                                                                              width: media.width * 0.06,
                                                                            ),
                                                                            Expanded(
                                                                              child: MyText(
                                                                                text: userRequestData['pick_address'],
                                                                                size: media.width * twelve,
                                                                                // maxLines: 1,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                              ],
                                                            )),
                                                      (userRequestData[
                                                                  'is_trip_start'] !=
                                                              1)
                                                          ? Column(
                                                              children: [
                                                                SizedBox(
                                                                  height: media
                                                                          .width *
                                                                      0.05,
                                                                ),
                                                                Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    (userRequestData['is_trip_start'] !=
                                                                            1)
                                                                        ? Button(
                                                                            width:
                                                                                Responsive.width(70, context),
                                                                            textcolor:
                                                                                Color(0xffFB5B5B),
                                                                            color:
                                                                                Colors.transparent,
                                                                            borcolor:
                                                                                Colors.transparent,
                                                                            onTap:
                                                                                () async {
                                                                              setState(() {
                                                                                _isLoading = true;
                                                                              });
                                                                              var reason = await cancelReason((userRequestData['is_driver_arrived'] == 0) ? 'before' : 'after');
                                                                              if (reason == true) {
                                                                                setState(() {
                                                                                  _cancellingError = '';
                                                                                  _cancelReason = '';
                                                                                  _cancelling = true;
                                                                                });
                                                                              }
                                                                              setState(() {
                                                                                _isLoading = false;
                                                                              });
                                                                            },
                                                                            text:
                                                                                languages[choosenLanguage]['text_cancel_booking'],
                                                                          )
                                                                        : Container(),
                                                                  ],
                                                                ),
                                                              ],
                                                            )
                                                          : Container(),
                                                    ],
                                                  ),
                                                )),
                                          ))
                                      : Container(),

                                  //cancel request
                                  (_cancelling == true)
                                      ? Positioned(
                                          child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _cancelling = false;
                                            });
                                          },
                                          child: Container(
                                            height: media.height,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisAlignment:
                                                    _cancelReason == 'others'
                                                        ? MainAxisAlignment
                                                            .center
                                                        : MainAxisAlignment
                                                            .center,
                                                children: [
                                                  SizedBox(
                                                    height: Responsive.height(
                                                        _cancelReason ==
                                                                'others'
                                                            ? 5
                                                            : 20,
                                                        context),
                                                  ),
                                                  Container(
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.05),
                                                    width: media.width * 0.9,
                                                    decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: white
                                                                .withOpacity(
                                                                    0.3)),
                                                        color: page,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30)),
                                                    child: Column(children: [
                                                      SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                1, context),
                                                      ),
                                                      MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_cancel_ride_dialog'],
                                                        size: media.width *
                                                            twentyeight,
                                                        fontweight:
                                                            FontWeight.w600,
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                1, context),
                                                      ),
                                                      Column(
                                                        children:
                                                            cancelReasonsList
                                                                .asMap()
                                                                .map(
                                                                    (i, value) {
                                                                  return MapEntry(
                                                                      i,
                                                                      InkWell(
                                                                        onTap:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            _cancelReason =
                                                                                cancelReasonsList[i]['reason'];
                                                                          });
                                                                        },
                                                                        child:
                                                                            Container(
                                                                          padding:
                                                                              EdgeInsets.all(media.width * 0.01),
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              Container(
                                                                                height: media.height * 0.04,
                                                                                width: media.width * 0.05,
                                                                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: buttonColor, width: 1.2)),
                                                                                alignment: Alignment.center,
                                                                                child: (_cancelReason == cancelReasonsList[i]['reason'])
                                                                                    ? Container(
                                                                                        height: media.width * 0.03,
                                                                                        width: media.width * 0.03,
                                                                                        decoration: BoxDecoration(
                                                                                          shape: BoxShape.circle,
                                                                                          color: buttonColor,
                                                                                        ),
                                                                                      )
                                                                                    : Container(),
                                                                              ),
                                                                              SizedBox(
                                                                                width: media.width * 0.05,
                                                                              ),
                                                                              SizedBox(
                                                                                  width: media.width * 0.65,
                                                                                  child: MyText(
                                                                                    text: cancelReasonsList[i]['reason'],
                                                                                    size: media.width * thirteen,
                                                                                  ))
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ));
                                                                })
                                                                .values
                                                                .toList(),
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            _cancelReason =
                                                                'others';
                                                          });
                                                        },
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  media.width *
                                                                      0.01),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                height: media
                                                                        .height *
                                                                    0.05,
                                                                width: media
                                                                        .width *
                                                                    0.05,
                                                                decoration: BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    border: Border.all(
                                                                        color:
                                                                            buttonColor,
                                                                        width:
                                                                            1.2)),
                                                                alignment:
                                                                    Alignment
                                                                        .center,
                                                                child: (_cancelReason ==
                                                                        'others')
                                                                    ? Container(
                                                                        height: media.width *
                                                                            0.03,
                                                                        width: media.width *
                                                                            0.03,
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          color:
                                                                              buttonColor,
                                                                        ),
                                                                      )
                                                                    : Container(),
                                                              ),
                                                              SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.05,
                                                              ),
                                                              MyText(
                                                                text: languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_others'],
                                                                size: media
                                                                        .width *
                                                                    twelve,
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      (_cancelReason ==
                                                              'others')
                                                          ? Container(
                                                              margin: EdgeInsets
                                                                  .fromLTRB(
                                                                      0,
                                                                      media.width *
                                                                          0.025,
                                                                      0,
                                                                      media.width *
                                                                          0.025),
                                                              padding: EdgeInsets.only(
                                                                  left: media
                                                                          .width *
                                                                      0.05,
                                                                  right: media
                                                                          .width *
                                                                      0.05),
                                                              // height: media.width*0.2,
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              decoration: BoxDecoration(
                                                                  color:
                                                                      darkModeSecContainer,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12)),
                                                              child: TextField(
                                                                decoration: InputDecoration(
                                                                    border:
                                                                        InputBorder
                                                                            .none,
                                                                    hintText:
                                                                        languages[choosenLanguage]
                                                                            [
                                                                            'text_cancelRideReason'],
                                                                    hintStyle: GoogleFonts.inter(
                                                                        color: textColor.withOpacity(
                                                                            0.4),
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w400,
                                                                        fontSize:
                                                                            media.width *
                                                                                fourteen)),
                                                                style: GoogleFonts
                                                                    .inter(
                                                                        color:
                                                                            textColor),
                                                                maxLines: 4,
                                                                minLines: 2,
                                                                onChanged:
                                                                    (val) {
                                                                  setState(() {
                                                                    _cancelCustomReason =
                                                                        val;
                                                                  });
                                                                },
                                                              ),
                                                            )
                                                          : Container(),
                                                      (_cancellingError != '')
                                                          ? Container(
                                                              padding: EdgeInsets.only(
                                                                  top: media
                                                                          .width *
                                                                      0.02,
                                                                  bottom:
                                                                      media.width *
                                                                          0.02),
                                                              width:
                                                                  media.width *
                                                                      0.9,
                                                              child: Text(
                                                                  _cancellingError,
                                                                  style: GoogleFonts.inter(
                                                                      fontSize:
                                                                          media.width *
                                                                              twelve,
                                                                      color: Colors
                                                                          .red)))
                                                          : Container(),
                                                      SizedBox(
                                                        height:
                                                            Responsive.height(
                                                                2, context),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Button(
                                                                color: Color(
                                                                    0xffFB5B5B),
                                                                textcolor:
                                                                    white,
                                                                borcolor: Colors
                                                                    .transparent,
                                                                width: media
                                                                        .width *
                                                                    0.39,
                                                                onTap:
                                                                    () async {
                                                                  setState(() {
                                                                    _isLoading =
                                                                        true;
                                                                  });
                                                                  if (_cancelReason !=
                                                                      '') {
                                                                    if (_cancelReason ==
                                                                        'others') {
                                                                      if (_cancelCustomReason !=
                                                                              '' &&
                                                                          _cancelCustomReason
                                                                              .isNotEmpty) {
                                                                        _cancellingError =
                                                                            '';
                                                                        var val =
                                                                            await cancelRequestWithReason(_cancelCustomReason);
                                                                        if (val ==
                                                                            'logout') {
                                                                          navigateLogout();
                                                                        }
                                                                        setState(
                                                                            () {
                                                                          _cancelling =
                                                                              false;
                                                                        });
                                                                      } else {
                                                                        setState(
                                                                            () {
                                                                          _cancellingError =
                                                                              languages[choosenLanguage]['text_add_cancel_reason'];
                                                                        });
                                                                      }
                                                                    } else {
                                                                      var val =
                                                                          await cancelRequestWithReason(
                                                                              _cancelReason);
                                                                      if (val ==
                                                                          'logout') {
                                                                        navigateLogout();
                                                                      }
                                                                      setState(
                                                                          () {
                                                                        _cancelling =
                                                                            false;
                                                                      });
                                                                    }
                                                                  } else {}
                                                                  setState(() {
                                                                    _isLoading =
                                                                        false;
                                                                  });
                                                                },
                                                                borderRadius:
                                                                    3000.0,
                                                                text: languages[
                                                                        choosenLanguage]
                                                                    [
                                                                    'text_cancel_ride']),
                                                          ),
                                                          SizedBox(
                                                            width: 15,
                                                          ),
                                                          Expanded(
                                                            child: Button(
                                                                width: media
                                                                        .width *
                                                                    0.39,
                                                                onTap: () {
                                                                  setState(() {
                                                                    _cancelling =
                                                                        false;
                                                                  });
                                                                },
                                                                borderRadius:
                                                                    3000.0,
                                                                text: languages[choosenLanguage]?['tex_dontcancel'] ?? "Don't Cancel"),
                                                          )
                                                        ],
                                                      )
                                                    ]),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ))
                                      : Container(),

                                  //date picker for ride later
                                  (_dateTimePicker == true)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Stack(
                                                  alignment: Alignment.topRight,
                                                  children: [
                                                    Container(
                                                      height:
                                                          media.height * 0.35,
                                                      width: media.width * 0.9,
                                                      decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                          border: Border.all(
                                                              color: white
                                                                  .withOpacity(
                                                                      0.3)),
                                                          color:
                                                              darkModeDialogColor),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          SizedBox(
                                                            height: Responsive
                                                                .height(
                                                                    3, context),
                                                          ),
                                                          Container(
                                                            height:
                                                                media.height *
                                                                    0.2,
                                                            width: media.width *
                                                                0.9,
                                                            child:
                                                                CupertinoDatePicker(
                                                                    use24hFormat:
                                                                        true,
                                                                    minimumDate: DateTime.now().add(Duration(
                                                                        minutes:
                                                                            int.parse(userDetails[
                                                                                'user_can_make_a_ride_after_x_miniutes']))),
                                                                    initialDateTime:
                                                                        DateTime.now().add(Duration(
                                                                            minutes: int.parse(userDetails[
                                                                                'user_can_make_a_ride_after_x_miniutes']))),
                                                                    maximumDate:
                                                                        DateTime.now().add(const Duration(
                                                                            days:
                                                                                4)),
                                                                    onDateTimeChanged:
                                                                        (val) {
                                                                      choosenDateTime =
                                                                          val;
                                                                    }),
                                                          ),
                                                          Container(
                                                              padding: EdgeInsets
                                                                  .all(media
                                                                          .width *
                                                                      0.05),
                                                              child: Button(
                                                                  onTap: () {
                                                                    setState(
                                                                        () {
                                                                      _dateTimePicker =
                                                                          false;
                                                                      _confirmRideLater =
                                                                          true;
                                                                    });
                                                                  },
                                                                  text: languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_confirm']))
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 15,
                                                      right: 15,
                                                      child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _dateTimePicker =
                                                                  false;
                                                            });
                                                          },
                                                          child: Icon(
                                                              Icons.cancel,
                                                              color:
                                                                  textColor)),
                                                    )
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ))
                                      : Container(),

                                  //confirm ride later
                                  (_confirmRideLater == true)
                                      ? Positioned(
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Stack(
                                                  alignment: Alignment.topRight,
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.04),
                                                      width: media.width * 0.9,
                                                      decoration: BoxDecoration(
                                                          border: Border.all(
                                                              color: white
                                                                  .withOpacity(
                                                                      0.3)),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(30),
                                                          color:
                                                              darkModeDialogColor),
                                                      child: Column(
                                                        children: [
                                                          SizedBox(
                                                            height: Responsive
                                                                .height(3.5,
                                                                    context),
                                                          ),
                                                          Text(
                                                            languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_confirmridelater'],
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: GoogleFonts.inter(
                                                                fontSize: media
                                                                        .width *
                                                                    thirteen,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color:
                                                                    textColor),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                media.width *
                                                                    0.03,
                                                          ),
                                                          Text(
                                                            DateFormat()
                                                                .format(
                                                                    choosenDateTime)
                                                                .toString(),
                                                            style: GoogleFonts.inter(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                media.width *
                                                                    0.05,
                                                          ),
                                                          Button(
                                                              onTap: () async {
                                                                if (widget
                                                                        .type !=
                                                                    1) {
                                                                  if (etaDetails[
                                                                              choosenVehicle]
                                                                          [
                                                                          'has_discount'] ==
                                                                      false) {
                                                                    dynamic val;
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          true;
                                                                    });

                                                                    val =
                                                                        await createRequestLater();
                                                                    if (val ==
                                                                        'logout') {
                                                                      navigateLogout();
                                                                    }
                                                                    setState(
                                                                        () {
                                                                      if (val ==
                                                                          'success') {
                                                                        _isLoading =
                                                                            false;
                                                                        _confirmRideLater =
                                                                            false;
                                                                        _rideLaterSuccess =
                                                                            true;
                                                                      }
                                                                    });
                                                                  } else {
                                                                    dynamic val;
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          true;
                                                                    });

                                                                    val =
                                                                        await createRequestLaterPromo();
                                                                    if (val ==
                                                                        'logout') {
                                                                      navigateLogout();
                                                                    }
                                                                    setState(
                                                                        () {
                                                                      if (val ==
                                                                          'success') {
                                                                        _isLoading =
                                                                            false;

                                                                        _confirmRideLater =
                                                                            false;
                                                                        _rideLaterSuccess =
                                                                            true;
                                                                      }
                                                                    });
                                                                  }
                                                                } else {
                                                                  if (rentalOption[
                                                                              choosenVehicle]
                                                                          [
                                                                          'has_discount'] ==
                                                                      false) {
                                                                    dynamic val;
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          true;
                                                                    });

                                                                    val =
                                                                        await createRentalRequestLater();
                                                                    if (val ==
                                                                        'logout') {
                                                                      navigateLogout();
                                                                    }
                                                                    setState(
                                                                        () {
                                                                      if (val ==
                                                                          'success') {
                                                                        _isLoading =
                                                                            false;
                                                                        _confirmRideLater =
                                                                            false;
                                                                        _rideLaterSuccess =
                                                                            true;
                                                                      }
                                                                    });
                                                                  } else {
                                                                    dynamic val;
                                                                    setState(
                                                                        () {
                                                                      _isLoading =
                                                                          true;
                                                                    });

                                                                    val =
                                                                        await createRentalRequestLaterPromo();
                                                                    if (val ==
                                                                        'logout') {
                                                                      navigateLogout();
                                                                    }
                                                                    setState(
                                                                        () {
                                                                      if (val ==
                                                                          'success') {
                                                                        _isLoading =
                                                                            false;

                                                                        _confirmRideLater =
                                                                            false;
                                                                        _rideLaterSuccess =
                                                                            true;
                                                                      }
                                                                    });
                                                                  }
                                                                  setState(() {
                                                                    _isLoading =
                                                                        false;
                                                                  });
                                                                }
                                                              },
                                                              text: languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_confirm']),
                                                          SizedBox(
                                                            height: Responsive
                                                                .height(
                                                                    1, context),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 15,
                                                      right: 15,
                                                      child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              _dateTimePicker =
                                                                  true;
                                                              _confirmRideLater =
                                                                  false;
                                                            });
                                                          },
                                                          child: const Icon(
                                                              Icons.cancel)),
                                                    )
                                                  ],
                                                )
                                              ],
                                            ),
                                          ),
                                        )
                                      : Container(),

                                  //ride later success
                                  (_rideLaterSuccess == true)
                                      ? Positioned(
                                          child: Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          color: Colors.transparent
                                              .withOpacity(0.6),
                                          child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                  width: media.width * 0.9,
                                                  decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      color: page),
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_rideLaterSuccess'],
                                                        style:
                                                            GoogleFonts.inter(
                                                                fontSize: media
                                                                        .width *
                                                                    fourteen,
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            media.width * 0.05,
                                                      ),
                                                      Button(
                                                          onTap: () {
                                                            addressList.removeWhere(
                                                                (element) =>
                                                                    element
                                                                        .type ==
                                                                    'drop');
                                                            _rideLaterSuccess =
                                                                false;
                                                            myMarker.clear();
                                                            Navigator.pushAndRemoveUntil(
                                                                context,
                                                                MaterialPageRoute(
                                                                    builder:
                                                                        (context) =>
                                                                            const Maps()),
                                                                (route) =>
                                                                    false);
                                                          },
                                                          text: languages[
                                                                  choosenLanguage]
                                                              ['text_confirm'])
                                                    ],
                                                  ),
                                                )
                                              ]),
                                        ))
                                      : Container(),

                                  //sos popup
                                  (showSos == true)
                                      ? Positioned(
                                          top: 0,
                                          child: Container(
                                            height: media.height * 1,
                                            width: media.width * 1,
                                            color: Colors.transparent
                                                .withOpacity(0.6),
                                            child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Stack(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.fromLTRB(
                                                            Responsive.width(
                                                                5, context),
                                                            Responsive.height(
                                                                4, context),
                                                            Responsive.width(
                                                                5, context),
                                                            Responsive.height(
                                                                4, context)),
                                                        width:
                                                            media.width * 0.9,
                                                        decoration: BoxDecoration(
                                                            border: Border.all(
                                                                color: darkModeBorderColor
                                                                    .withAlpha(
                                                                        100)),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        30),
                                                            color: page),
                                                        child:
                                                            SingleChildScrollView(
                                                                physics:
                                                                    const BouncingScrollPhysics(),
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    InkWell(
                                                                      onTap:
                                                                          () async {
                                                                        setState(
                                                                            () {
                                                                          notifyCompleted =
                                                                              false;
                                                                        });
                                                                        var val =
                                                                            await notifyAdmin();
                                                                        if (val ==
                                                                            true) {
                                                                          setState(
                                                                              () {
                                                                            notifyCompleted =
                                                                                true;
                                                                          });
                                                                        }
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        padding:
                                                                            EdgeInsets.all(media.width *
                                                                                0.05),
                                                                        child:
                                                                            Row(
                                                                          mainAxisAlignment:
                                                                              MainAxisAlignment.spaceBetween,
                                                                          children: [
                                                                            Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  languages[choosenLanguage]?['text_notifyadmin'] ?? 'Notify Admin',
                                                                                  style: GoogleFonts.inter(fontSize: 17, color: textColor, fontWeight: FontWeight.w500),
                                                                                ),
                                                                                (notifyCompleted == true)
                                                                                    ? Container(
                                                                                        padding: EdgeInsets.only(top: media.width * 0.01),
                                                                                        child: Text(
                                                                                          languages[choosenLanguage]['text_notifysuccess'],
                                                                                          style: GoogleFonts.inter(
                                                                                            fontSize: media.width * twelve,
                                                                                            color: const Color(0xff319900),
                                                                                          ),
                                                                                        ),
                                                                                      )
                                                                                    : Container()
                                                                              ],
                                                                            ),
                                                                            Icon(
                                                                              Icons.notifications_none_outlined,
                                                                              color: textColor,
                                                                            )
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    (sosData.isNotEmpty)
                                                                        ? Column(
                                                                            children: sosData
                                                                                .asMap()
                                                                                .map((i, value) {
                                                                                  return MapEntry(
                                                                                      i,
                                                                                      InkWell(
                                                                                        onTap: () {
                                                                                          makingPhoneCall(sosData[i]['number'].toString().replaceAll(' ', ''));
                                                                                        },
                                                                                        child: Container(
                                                                                          padding: EdgeInsets.all(media.width * 0.03),
                                                                                          child: Row(
                                                                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                            children: [
                                                                                              Column(
                                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                children: [
                                                                                                  SizedBox(
                                                                                                    width: media.width * 0.4,
                                                                                                    child: Text(
                                                                                                      sosData[i]['name'],
                                                                                                      style: GoogleFonts.inter(fontSize: 17, color: textColor, fontWeight: FontWeight.w500),
                                                                                                    ),
                                                                                                  ),
                                                                                                  SizedBox(
                                                                                                    height: media.width * 0.01,
                                                                                                  ),
                                                                                                  Text(
                                                                                                    sosData[i]['number'],
                                                                                                    style: GoogleFonts.inter(
                                                                                                      fontSize: 17,
                                                                                                      fontWeight: FontWeight.w300,
                                                                                                      color: textColor.withOpacity(0.53),
                                                                                                    ),
                                                                                                  )
                                                                                                ],
                                                                                              ),
                                                                                              Icon(
                                                                                                Icons.call,
                                                                                                color: textColor,
                                                                                              )
                                                                                            ],
                                                                                          ),
                                                                                        ),
                                                                                      ));
                                                                                })
                                                                                .values
                                                                                .toList(),
                                                                          )
                                                                        : Container(
                                                                            width:
                                                                                media.width * 0.7,
                                                                            alignment:
                                                                                Alignment.center,
                                                                            child:
                                                                                Text(
                                                                              languages[choosenLanguage]['text_no_complaints'],
                                                                              style: GoogleFonts.inter(fontSize: media.width * eighteen, fontWeight: FontWeight.w600, color: textColor),
                                                                            ),
                                                                          ),
                                                                  ],
                                                                )),
                                                      ),
                                                      Positioned(
                                                        top: 10,
                                                        right: 10,
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              notifyCompleted =
                                                                  false;
                                                              showSos = false;
                                                            });
                                                          },
                                                          child: Container(
                                                            height:
                                                                media.width *
                                                                    0.1,
                                                            width: media.width *
                                                                0.1,
                                                            decoration:
                                                                BoxDecoration(
                                                                    shape: BoxShape
                                                                        .circle,
                                                                    color:
                                                                        page),
                                                            child: Icon(
                                                              Icons
                                                                  .cancel_rounded,
                                                              color: textColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  )
                                                ]),
                                          ))
                                      : Container(),

                                  (_locationDenied == true)
                                      ? Positioned(
                                          child: Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          color: Colors.transparent
                                              .withOpacity(0.6),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Stack(
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.05),
                                                    width: media.width * 0.9,
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                        color:
                                                            darkModeDialogColor,
                                                        border: Border.all(
                                                            color: white
                                                                .withOpacity(
                                                                    0.3))),
                                                    child: Column(
                                                      children: [
                                                        SizedBox(
                                                          height:
                                                              Responsive.height(
                                                                  4.5, context),
                                                        ),
                                                        SizedBox(
                                                            width: media.width *
                                                                0.8,
                                                            child: Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_open_loc_settings'],
                                                              style: GoogleFonts.inter(
                                                                  fontSize: media
                                                                          .width *
                                                                      fifteen,
                                                                  color:
                                                                      textColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400),
                                                            )),
                                                        SizedBox(
                                                            height:
                                                                media.width *
                                                                    0.07),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceAround,
                                                          children: [
                                                            Expanded(
                                                              child: Button(
                                                                  borcolor: Colors
                                                                      .transparent,
                                                                  borderRadius:
                                                                      3000.0,
                                                                  color:
                                                                      darkModeSecContainer,
                                                                  onTap:
                                                                      () async {
                                                                    await perm
                                                                        .openAppSettings();
                                                                  },
                                                                  text: languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_open_settings']),
                                                            ),
                                                            SizedBox(
                                                              width: 20,
                                                            ),
                                                            Expanded(
                                                              child: Button(
                                                                  borderRadius:
                                                                      3000.0,
                                                                  onTap:
                                                                      () async {
                                                                    setState(
                                                                        () {
                                                                      _locationDenied =
                                                                          false;
                                                                      _isLoading =
                                                                          true;
                                                                    });

                                                                    if (locationAllowed ==
                                                                        true) {
                                                                      if (positionStream ==
                                                                              null ||
                                                                          positionStream!
                                                                              .isPaused) {
                                                                        positionStreamData();
                                                                      }
                                                                    }
                                                                  },
                                                                  text: languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_done']),
                                                            )
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  Positioned(
                                                    top: 15,
                                                    right: 15,
                                                    child: InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          _locationDenied =
                                                              false;
                                                        });
                                                      },
                                                      child: Icon(Icons.cancel,
                                                          color: textColor),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ))
                                      : Container(),

                                  ((dropConfirmed == false &&
                                          userRequestData.isEmpty))
                                      ? Positioned(
                                          bottom: 0,
                                          child: Container(
                                              width: media.width * 1,
                                              padding: EdgeInsets.all(
                                                  media.width * 0.05),
                                              decoration: BoxDecoration(
                                                  color: darkModeDialogColor,
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                          top: Radius.circular(
                                                              30))),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  SizedBox(
                                                    height: media.width * 0.025,
                                                  ),
                                                  Stack(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          InkWell(
                                                            onTap: () async {
                                                              var nav = await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) => DropLocation(
                                                                            from:
                                                                                addressList[0].id,
                                                                          )));
                                                              if (nav) {
                                                                setState(() {});
                                                                Future.delayed(
                                                                    const Duration(
                                                                        milliseconds:
                                                                            100),
                                                                    () {
                                                                  addPickDropMarker();
                                                                });
                                                              }
                                                            },
                                                            child: Container(
                                                              padding: EdgeInsets.fromLTRB(
                                                                  media.width *
                                                                      0.03,
                                                                  media.width *
                                                                      0.0,
                                                                  media.width *
                                                                      0.03,
                                                                  media.width *
                                                                      0.0),
                                                              decoration: BoxDecoration(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                          media.width *
                                                                              0.02),
                                                                  color:
                                                                      darkModeDialogColor),
                                                              height:
                                                                  media.width *
                                                                      0.11,
                                                              width: media
                                                                      .width *
                                                                  (((addressList.length <
                                                                              5 &&
                                                                          widget.type !=
                                                                              1))
                                                                      ? 0.75
                                                                      : 0.9),
                                                              child: Column(
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Container(
                                                                        height: media.width *
                                                                            0.025,
                                                                        width: media.width *
                                                                            0.025,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        decoration: BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color: const Color(0xff319900).withOpacity(0.3)),
                                                                        child:
                                                                            Container(
                                                                          height:
                                                                              media.width * 0.01,
                                                                          width:
                                                                              media.width * 0.01,
                                                                          decoration: const BoxDecoration(
                                                                              shape: BoxShape.circle,
                                                                              color: Color(0xff319900)),
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.05,
                                                                      ),
                                                                      Expanded(
                                                                        child:
                                                                            Text(
                                                                          addressList[0]
                                                                              .address
                                                                              .toString(),
                                                                          style: GoogleFonts.inter(
                                                                              color: textColor,
                                                                              fontSize: media.width * twelve),
                                                                          maxLines:
                                                                              1,
                                                                          overflow:
                                                                              TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      SizedBox(
                                                                        width: media.width *
                                                                            0.02,
                                                                      ),
                                                                      SizedBox(
                                                                          height: media.width *
                                                                              0.07,
                                                                          child:
                                                                              Icon(
                                                                            Icons.edit,
                                                                            color:
                                                                                textColor,
                                                                            size:
                                                                                media.width * 0.05,
                                                                          ))
                                                                    ],
                                                                  ),
                                                                  SizedBox(
                                                                    height: 5,
                                                                  ),
                                                                  Container(
                                                                    width: media
                                                                            .width *
                                                                        0.9,
                                                                    height: 1,
                                                                    color: darkModeBorderColor
                                                                        .withAlpha(
                                                                            100),
                                                                  )
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          FutureBuilder(
                                                            future: Future
                                                                .delayed(Duration(
                                                                    milliseconds:
                                                                        100)),
                                                            builder: (context,
                                                                snapshot) {
                                                              // if (addressList.any(
                                                              //     (element) =>
                                                              //         element.latlng ==
                                                              //         destinationDropOff)) {
                                                              //   AddressList item =
                                                              //       addressList.firstWhere(
                                                              //           (element) =>
                                                              //               element
                                                              //                   .latlng ==
                                                              //               destinationDropOff);
                                                              //   addressList
                                                              //       .remove(item);
                                                              //   addressList.add(item);
                                                              // }

                                                              return SizedBox(
                                                                height: (addressList
                                                                            .length <=
                                                                        4)
                                                                    ? media.width *
                                                                        0.125 *
                                                                        (addressList.length -
                                                                            1)
                                                                    : media.width *
                                                                        0.125 *
                                                                        4,
                                                                child: ReorderableListView(
                                                                    onReorder: (oldIndex, newIndex) {
                                                                      if (oldIndex != 0 &&
                                                                          newIndex !=
                                                                              0 &&
                                                                          newIndex <
                                                                              addressList.length) {
                                                                        var val1 =
                                                                            addressList[oldIndex]; //1
                                                                        var id1 =
                                                                            addressList[oldIndex].id;
                                                                        var val2 =
                                                                            addressList[newIndex]; //2
                                                                        var id2 =
                                                                            addressList[newIndex].id;

                                                                        addressList[oldIndex] =
                                                                            val2; //2
                                                                        addressList[oldIndex].id =
                                                                            id1; //1
                                                                        addressList[newIndex] =
                                                                            val1; //1
                                                                        addressList[newIndex].id =
                                                                            id2; //2
                                                                      } else if (newIndex >
                                                                          addressList.length -
                                                                              1) {
                                                                        var newIndexEdit =
                                                                            addressList.length -
                                                                                1;

                                                                        var val1 =
                                                                            addressList[oldIndex]; //1
                                                                        var id1 =
                                                                            addressList[oldIndex].id;
                                                                        var val2 =
                                                                            addressList[newIndexEdit]; //2
                                                                        var id2 =
                                                                            addressList[newIndexEdit].id;
                                                                        addressList[oldIndex] =
                                                                            val2; //2
                                                                        addressList[oldIndex].id =
                                                                            id1; //1
                                                                        addressList[newIndexEdit] =
                                                                            val1; //1
                                                                        addressList[newIndexEdit].id =
                                                                            id2; //2
                                                                      }
                                                                      setState(
                                                                          () {
                                                                        addPickDropMarker();
                                                                      });
                                                                    },
                                                                    children: addressList
                                                                        .asMap()
                                                                        .map((i, value) {
                                                                          return MapEntry(
                                                                            i,
                                                                            (i != 0)
                                                                                ? Container(
                                                                                    key: ValueKey(i),
                                                                                    margin: EdgeInsets.only(bottom: media.width * 0.025),
                                                                                    alignment: Alignment.center,
                                                                                    height: media.width * 0.1,
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                      crossAxisAlignment: CrossAxisAlignment.center,
                                                                                      children: [
                                                                                        InkWell(
                                                                                          onTap: () async {
                                                                                            // int index = 0;
                                                                                            // if (i == 1) {
                                                                                            //   index = 0;
                                                                                            // } else {
                                                                                            //   index = 1;
                                                                                            // }

                                                                                            var val = await Navigator.push(
                                                                                                context,
                                                                                                MaterialPageRoute(
                                                                                                    builder: (context) => DropLocation(
                                                                                                          from: addressList[i].id,
                                                                                                        )));
                                                                                            if (val) {
                                                                                              setState(() {});
                                                                                              Future.delayed(const Duration(milliseconds: 100), () {
                                                                                                addPickDropMarker();
                                                                                              });
                                                                                            }
                                                                                            // if (addressList[i].latlng == destinationDropOff) {
                                                                                            //   var navigate = await Navigator.push(context, MaterialPageRoute(builder: (context) => DropLocation()));
                                                                                            //   if (navigate != null) {
                                                                                            //     destinationAddress = [];
                                                                                            //     destinationAddress = addressList.where((element) => element.type == 'drop').toList();
                                                                                            //     destinationDropOff = destinationLocation;
                                                                                            //     setState(() {});
                                                                                            //     Future.delayed(const Duration(milliseconds: 100), () {
                                                                                            //       addPickDropMarker();
                                                                                            //     });
                                                                                            //   }
                                                                                            // } else {
                                                                                            //   var val = await Navigator.push(
                                                                                            //       context,
                                                                                            //       MaterialPageRoute(
                                                                                            //           builder: (context) => DropLocation(
                                                                                            //                 from: addressList[i].id,
                                                                                            //               )));
                                                                                            //   if (val) {
                                                                                            //     setState(() {});
                                                                                            //     Future.delayed(const Duration(milliseconds: 100), () {
                                                                                            //       addPickDropMarker();
                                                                                            //     });
                                                                                            //   }
                                                                                            // }
                                                                                          },
                                                                                          child: Container(
                                                                                            padding: EdgeInsets.fromLTRB(media.width * 0.03, media.width * 0.0, media.width * 0.03, media.width * 0.0),
                                                                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(media.width * 0.02), color: darkModeDialogColor),
                                                                                            alignment: Alignment.center,
                                                                                            height: media.width * 0.15,
                                                                                            width: media.width * (((addressList.length < 5 && widget.type != 1)) ? 0.75 : 0.9),
                                                                                            child: Column(
                                                                                              children: [
                                                                                                Row(
                                                                                                  children: [
                                                                                                    Container(
                                                                                                      height: media.width * 0.025,
                                                                                                      width: media.width * 0.025,
                                                                                                      alignment: Alignment.center,
                                                                                                      decoration: BoxDecoration(shape: BoxShape.circle, color: (i == 0) ? const Color(0xff319900).withOpacity(0.3) : const Color(0xffFF0000).withOpacity(0.3)),
                                                                                                      child: Container(
                                                                                                        height: media.width * 0.01,
                                                                                                        width: media.width * 0.01,
                                                                                                        decoration: BoxDecoration(shape: BoxShape.circle, color: (i == 0) ? const Color(0xff319900) : const Color(0xffFF0000)),
                                                                                                      ),
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.05,
                                                                                                    ),
                                                                                                    Expanded(
                                                                                                      child: Text(
                                                                                                        addressList[i].address.toString(),
                                                                                                        style: GoogleFonts.inter(
                                                                                                          fontSize: media.width * twelve,
                                                                                                          color: textColor,
                                                                                                        ),
                                                                                                        maxLines: 1,
                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                      ),
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.02,
                                                                                                    ),
                                                                                                    SizedBox(
                                                                                                        height: media.width * 0.07,
                                                                                                        child: (addressList.length > 2)
                                                                                                            ? Icon(
                                                                                                                Icons.move_down_rounded,
                                                                                                                size: media.width * 0.05,
                                                                                                                color: textColor,
                                                                                                              )
                                                                                                            : Icon(
                                                                                                                Icons.edit,
                                                                                                                color: textColor,
                                                                                                                size: media.width * 0.05,
                                                                                                              )),
                                                                                                    SizedBox(
                                                                                                      width: 10,
                                                                                                    ),
                                                                                                    (addressList.length > 2)
                                                                                                        ? InkWell(
                                                                                                            onTap: () {
                                                                                                              setState(() {
                                                                                                                addressList.removeAt(i);
                                                                                                                myMarker.removeWhere((element) => element.markerId.toString().contains('car') != true);
                                                                                                                addPickDropMarker();
                                                                                                              });
                                                                                                            },
                                                                                                            child: Icon(
                                                                                                              Icons.delete,
                                                                                                              size: media.width * 0.07,
                                                                                                              color: textColor,
                                                                                                            ))
                                                                                                        : Container()
                                                                                                  ],
                                                                                                ),
                                                                                                SizedBox(
                                                                                                  height: 5,
                                                                                                ),
                                                                                                Container(
                                                                                                  width: media.width * 0.9,
                                                                                                  height: 1,
                                                                                                  color: darkModeBorderColor.withAlpha(100),
                                                                                                )
                                                                                              ],
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  )
                                                                                : Container(
                                                                                    key: ValueKey(addressList[i].id),
                                                                                  ),
                                                                          );
                                                                        })
                                                                        .values
                                                                        .toList()),
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                      Visibility(
                                                        visible: (addressList
                                                                    .length <
                                                                5 &&
                                                            widget.type != 1),
                                                        child: Positioned(
                                                          right:
                                                              Responsive.width(
                                                                  0, context),
                                                          child: InkWell(
                                                            onTap: () async {
                                                              var nav = await Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                      builder: (context) => DropLocation(
                                                                            from:
                                                                                'add stop',
                                                                          )));
                                                              if (nav) {
                                                                setState(() {});
                                                                Future.delayed(
                                                                    const Duration(
                                                                        milliseconds:
                                                                            100),
                                                                    () {
                                                                  addPickDropMarker();
                                                                });
                                                              }
                                                            },
                                                            child: Container(
                                                              width: Responsive
                                                                  .width(15,
                                                                      context),
                                                              height: Responsive
                                                                  .height(8,
                                                                      context),
                                                              decoration: BoxDecoration(
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  color: Color(
                                                                      0xff212121)),
                                                              child: Icon(
                                                                Icons.add,
                                                                size: 30,
                                                                color: darkModeBorderColor
                                                                    .withAlpha(
                                                                        80),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                  Button(
                                                      onTap: () async {
                                                        setState(() {
                                                          _isLoading = true;
                                                          dropStopList.clear();
                                                          // addressList.add(
                                                          //     destinationAddress
                                                          //         .last);
                                                          if (addressList
                                                                  .length >
                                                              2) {
                                                            for (var i = 1;
                                                                i <
                                                                    addressList
                                                                        .length;
                                                                i++) {
                                                              dropStopList.add(DropStops(
                                                                  order: i
                                                                      .toString(),
                                                                  latitude:
                                                                      addressList[i]
                                                                          .latlng
                                                                          .latitude,
                                                                  longitude:
                                                                      addressList[i]
                                                                          .latlng
                                                                          .longitude,
                                                                  pocName:
                                                                      addressList[i]
                                                                          .name
                                                                          .toString(),
                                                                  pocNumber:
                                                                      addressList[i]
                                                                          .number
                                                                          .toString(),
                                                                  pocInstruction: (addressList[i]
                                                                              .instructions !=
                                                                          null)
                                                                      ? addressList[
                                                                              i]
                                                                          .instructions
                                                                      : null,
                                                                  address: addressList[
                                                                          i]
                                                                      .address
                                                                      .toString()));
                                                            }
                                                          }
                                                        });

                                                        if (widget.type != 1) {
                                                          var val =
                                                              await etaRequest();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          }
                                                        } else {
                                                          var val =
                                                              await rentalEta();
                                                          if (val == 'logout') {
                                                            navigateLogout();
                                                          }
                                                        }

                                                        setState(() {
                                                          dropConfirmed = true;
                                                          _isLoading = false;
                                                        });
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_confirm']),
                                                  ButtonBottomSpace()
                                                ],
                                              )),
                                        )
                                      : Container(),

                                  //loader
                                  (_isLoading == true)
                                      ? const Positioned(
                                          top: 0, child: Loading())
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

                                  //pick drop marker
                                  Positioned(
                                    top: media.height * 1.6,
                                    child: RepaintBoundary(
                                        key: iconKey,
                                        child: Column(
                                          children: [
                                            Visibility(
                                              visible: false,
                                              child: Container(
                                                  decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                          colors: [
                                                            (isDarkTheme ==
                                                                    true)
                                                                ? const Color(
                                                                    0xff000000)
                                                                : const Color(
                                                                    0xffFFFFFF),
                                                            (isDarkTheme ==
                                                                    true)
                                                                ? const Color(
                                                                    0xff808080)
                                                                : const Color(
                                                                    0xffEFEFEF),
                                                          ],
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5)),
                                                  width: (platform ==
                                                          TargetPlatform
                                                              .android)
                                                      ? media.width * 0.7
                                                      : media.width * 0.9,
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  child: (userRequestData
                                                          .isNotEmpty)
                                                      ? Text(
                                                          userRequestData[
                                                              'pick_address'],
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow.fade,
                                                          softWrap: false,
                                                          style: GoogleFonts.inter(
                                                              color: textColor,
                                                              fontSize: (platform ==
                                                                      TargetPlatform
                                                                          .android)
                                                                  ? media.width *
                                                                      twelve
                                                                  : media.width *
                                                                      sixteen),
                                                        )
                                                      : (addressList
                                                              .where((element) =>
                                                                  element
                                                                      .type ==
                                                                  'pickup')
                                                              .isNotEmpty)
                                                          ? Text(
                                                              addressList
                                                                  .firstWhere((element) =>
                                                                      element
                                                                          .type ==
                                                                      'pickup')
                                                                  .address,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .fade,
                                                              softWrap: false,
                                                              style: GoogleFonts.inter(
                                                                  color:
                                                                      textColor,
                                                                  fontSize: (platform ==
                                                                          TargetPlatform
                                                                              .android)
                                                                      ? media.width *
                                                                          twelve
                                                                      : media.width *
                                                                          sixteen),
                                                            )
                                                          : Container()),
                                            ),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Container(
                                              decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                      image: AssetImage(
                                                          'assets/images/Pick_icon.png'),
                                                      fit: BoxFit.contain)),
                                              height: (platform ==
                                                      TargetPlatform.android)
                                                  ? media.width * 0.07
                                                  : media.width * 0.12,
                                              width: (platform ==
                                                      TargetPlatform.android)
                                                  ? media.width * 0.07
                                                  : media.width * 0.12,
                                            ),
                                          ],
                                        )),
                                  ),
                                  (widget.type != 1)
                                      ? Positioned(
                                          top: media.height * 2,
                                          child: Column(
                                            children: addressList
                                                .asMap()
                                                .map((i, value) {
                                                  iconDropKeys[i] = GlobalKey();
                                                  return MapEntry(
                                                    i,
                                                    (i > 0)
                                                        ? RepaintBoundary(
                                                            key:
                                                                iconDropKeys[i],
                                                            child: Column(
                                                              children: [
                                                                (i ==
                                                                        addressList.length -
                                                                            1)
                                                                    ? Column(
                                                                        children: [
                                                                          Visibility(
                                                                            visible:
                                                                                false,
                                                                            child:
                                                                                Container(
                                                                              decoration: BoxDecoration(
                                                                                  gradient: LinearGradient(colors: [
                                                                                    (isDarkTheme == true) ? const Color(0xff000000) : const Color(0xffFFFFFF),
                                                                                    (isDarkTheme == true) ? const Color(0xff808080) : const Color(0xffEFEFEF),
                                                                                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                                                                  borderRadius: BorderRadius.circular(5)),
                                                                              width: (platform == TargetPlatform.android) ? media.width * 0.7 : media.width * 0.9,
                                                                              padding: const EdgeInsets.all(5),
                                                                              child: (addressList[i].address.isNotEmpty)
                                                                                  ? Text(
                                                                                      addressList[i].address,
                                                                                      maxLines: 1,
                                                                                      overflow: TextOverflow.fade,
                                                                                      softWrap: false,
                                                                                      style: GoogleFonts.inter(fontSize: (platform == TargetPlatform.android) ? media.width * twelve : media.width * sixteen, color: textColor),
                                                                                    )
                                                                                  : Container(),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(
                                                                            height:
                                                                                10,
                                                                          ),
                                                                          Container(
                                                                            decoration:
                                                                                const BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: AssetImage('assets/images/drop_icon.png'), fit: BoxFit.contain)),
                                                                            height: (platform == TargetPlatform.android)
                                                                                ? media.width * 0.07
                                                                                : media.width * 0.12,
                                                                            width: (platform == TargetPlatform.android)
                                                                                ? media.width * 0.07
                                                                                : media.width * 0.12,
                                                                          ),
                                                                        ],
                                                                      )
                                                                    : Text(
                                                                        (i).toString(),
                                                                        style: GoogleFonts.inter(
                                                                            fontSize: media.width *
                                                                                sixteen,
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                            color: Colors.red),
                                                                      ),
                                                              ],
                                                            ))
                                                        : Container(),
                                                  );
                                                })
                                                .values
                                                .toList(),
                                          ))
                                      : Container(),

                                  (widget.type != 1)
                                      ? Positioned(
                                          top: media.height * 2,
                                          child: RepaintBoundary(
                                              key: iconDistanceKey,
                                              child: Stack(
                                                children: [
                                                  Icon(Icons.chat_bubble,
                                                      size: media.width * 0.2,
                                                      color: page,
                                                      shadows: [
                                                        BoxShadow(
                                                            spreadRadius: 2,
                                                            blurRadius: 2,
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.2))
                                                      ]),
                                                  if (etaDetails.isNotEmpty)
                                                    if (etaDetails[0]
                                                            ['distance'] !=
                                                        null)
                                                      Positioned(
                                                          left: media.width *
                                                              0.03,
                                                          top: media.width *
                                                              0.03,
                                                          child: Container(
                                                              width:
                                                                  media.width *
                                                                      0.14,
                                                              height:
                                                                  media.width *
                                                                      0.1,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Text(
                                                                "${etaDetails[0]['distance'].toString()} ${etaDetails[0]['unit_in_words'].toString()} ",
                                                                style: GoogleFonts.inter(
                                                                    fontSize: media
                                                                            .width *
                                                                        twelve,
                                                                    color:
                                                                        textColor,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600),
                                                              )))
                                                ],
                                              )),
                                        )
                                      : Container()
                                ],
                              );
                            });
                      });
                }),
          ),
        ),
      ),
    );
  }

  double getBearing(LatLng begin, LatLng end) {
    double lat = (begin.latitude - end.latitude).abs();

    double lng = (begin.longitude - end.longitude).abs();

    if (begin.latitude < end.latitude && begin.longitude < end.longitude) {
      return vector.degrees(atan(lng / lat));
    } else if (begin.latitude >= end.latitude &&
        begin.longitude < end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 90;
    } else if (begin.latitude >= end.latitude &&
        begin.longitude >= end.longitude) {
      return vector.degrees(atan(lng / lat)) + 180;
    } else if (begin.latitude < end.latitude &&
        begin.longitude >= end.longitude) {
      return (90 - vector.degrees(atan(lng / lat))) + 270;
    }

    return -1;
  }

  animateCar(
      double fromLat, //Starting latitude

      double fromLong, //Starting longitude

      double toLat, //Ending latitude

      double toLong, //Ending longitude

      StreamSink<List<Marker>>
          mapMarkerSink, //Stream build of map to update the UI

      TickerProvider
          provider, //Ticker provider of the widget. This is used for animation

      GoogleMapController controller, //Google map controller of our widget

      markerid,
      markerBearing,
      icon) async {
    final double bearing =
        getBearing(LatLng(fromLat, fromLong), LatLng(toLat, toLong));

    myBearings[markerBearing.toString()] = bearing;

    var carMarker = Marker(
        markerId: MarkerId(markerid),
        position: LatLng(fromLat, fromLong),
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        draggable: false);

    myMarker.add(carMarker);

    mapMarkerSink.add(Set<Marker>.from(myMarker).toList());

    Tween<double> tween = Tween(begin: 0, end: 1);

    _animation = tween.animate(animationController)
      ..addListener(() async {
        myMarker
            .removeWhere((element) => element.markerId == MarkerId(markerid));

        final v = _animation!.value;

        double lng = v * toLong + (1 - v) * fromLong;

        double lat = v * toLat + (1 - v) * fromLat;

        LatLng newPos = LatLng(lat, lng);

        //New marker location

        carMarker = Marker(
            markerId: MarkerId(markerid),
            position: newPos,
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: bearing,
            draggable: false);

        //Adding new marker to our list and updating the google map UI.

        myMarker.add(carMarker);

        mapMarkerSink.add(Set<Marker>.from(myMarker).toList());
      });

    //Starting the animation

    animationController.forward();
  }
}
