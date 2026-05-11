import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui' as ui;
import '../../functions/functions.dart';
import '../../functions/geohash.dart';
import '../../functions/notifications.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../NavigatorPages/notification.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../navDrawer/nav_drawer.dart';
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:vector_math/vector_math.dart' as vector;

import '../noInternet/noInternet.dart';
import 'booking_confirmation.dart';
import 'drop_loc_select.dart';

class Maps extends StatefulWidget {
  const Maps({Key? key}) : super(key: key);

  @override
  State<Maps> createState() => _MapsState();
}

List<AddressList> destinationAddress = [];
dynamic serviceEnabled;
dynamic currentLocation;
LatLng center = const LatLng(41.4219057, -102.0840772);
String mapStyle = '';
List myMarkers = [];
Set<Marker> markers = {};
String dropAddressConfirmation = '';
LatLng? destinationLocation;
LatLng? destinationDropOff;
List<AddressList> addressList = <AddressList>[];
dynamic favLat;
dynamic favLng;
String favSelectedAddress = '';
String favName = 'Home';
String favNameText = '';
bool requestCancelledByDriver = false;
bool cancelRequestByUser = false;
bool logout = false;
bool deleteAccount = false;

class _MapsState extends State<Maps>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late TextEditingController pickupAddressController;
  late FocusNode dropLocFocusNode;
  // dynamic _currentCenter;
  dynamic _lastCenter;
  LatLng _centerLocation = const LatLng(41.4219057, -102.0840772);
  final _debouncer = Debouncer(milliseconds: 1000);

  dynamic animationController;
  dynamic _sessionToken;
  bool _loading = false;
  bool _pickaddress = false;
  bool _dropaddress = false;
  final bool _dropLocationMap = false;
  bool _locationDenied = false;
  int gettingPerm = 0;
  Animation<double>? _animation;

  late geolocs.LocationPermission permission;
  Location location = Location();
  String state = '';
  dynamic _controller;
  Map myBearings = {};

  dynamic pinLocationIcon;
  dynamic bikeIcon;
  dynamic userLocationIcon;
  bool favAddressAdd = false;
  bool contactus = false;
  bool _isDarkTheme = false;

  final _mapMarkerSC = StreamController<List<Marker>>();
  StreamSink<List<Marker>> get _mapMarkerSink => _mapMarkerSC.sink;
  Stream<List<Marker>> get carMarkerStream => _mapMarkerSC.stream;

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  @override
  void initState() {
    _isDarkTheme = isDarkTheme;
    WidgetsBinding.instance.addObserver(this);
    getLocs();
    getadminCurrentMessages();
    pickupAddressController = TextEditingController();
    dropLocFocusNode = FocusNode();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _bottom = 0;
      if (mounted) setState(() {});
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
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
    pickupAddressController.dispose();
    _controller?.dispose();
    _controller = null;
    animationController?.dispose();
    dropLocFocusNode.dispose();
    super.dispose();
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
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

//navigate
  navigate() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => BookingConfirmation()),
        (route) => false);
  }

//get location permission and location details
  getLocs() async {
    myBearings.clear;
    addressList.clear();
    serviceEnabled = await location.serviceEnabled();
    polyline.clear();
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/images/top-taxi.png', 60);
    pinLocationIcon = BitmapDescriptor.fromBytes(markerIcon);
    final Uint8List bikeIcons =
        await getBytesFromAsset('assets/images/bike.png', 40);
    bikeIcon = BitmapDescriptor.fromBytes(bikeIcons);

    permission = await geolocs.GeolocatorPlatform.instance.checkPermission();

    if (permission == geolocs.LocationPermission.denied ||
        permission == geolocs.LocationPermission.deniedForever ||
        serviceEnabled == false) {
      gettingPerm++;

      if (gettingPerm > 1 || locationAllowed == false) {
        state = '3';
        locationAllowed = false;
      } else {
        state = '2';
      }
      _loading = false;
      setState(() {});
    } else {
      var locs = await geolocs.Geolocator.getLastKnownPosition();
      if (locs != null) {
        setState(() {
          center = LatLng(double.parse(locs.latitude.toString()),
              double.parse(locs.longitude.toString()));
          _centerLocation = LatLng(double.parse(locs.latitude.toString()),
              double.parse(locs.longitude.toString()));
          currentLocation = LatLng(double.parse(locs.latitude.toString()),
              double.parse(locs.longitude.toString()));
          _lastCenter = _centerLocation;
        });
      } else {
        var loc = await geolocs.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocs.LocationAccuracy.low);
        setState(() {
          center = LatLng(double.parse(loc.latitude.toString()),
              double.parse(loc.longitude.toString()));
          _centerLocation = LatLng(double.parse(loc.latitude.toString()),
              double.parse(loc.longitude.toString()));
          currentLocation = LatLng(double.parse(loc.latitude.toString()),
              double.parse(loc.longitude.toString()));
          _lastCenter = _centerLocation;
        });
      }
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(center, 18.0));

      //remove in original

      var val =
          await geoCoding(_centerLocation.latitude, _centerLocation.longitude);
      setState(() {
        if (addressList
            .where((element) => element.type == 'pickup')
            .isNotEmpty) {
          var add =
              addressList.firstWhere((element) => element.type == 'pickup');
          add.address = val?.toString() ?? '';
          add.latlng =
              LatLng(_centerLocation.latitude, _centerLocation.longitude);
        } else {
          addressList.add(AddressList(
              id: '1',
              type: 'pickup',
              address: val?.toString() ?? '',
              pickup: true,
              latlng:
                  LatLng(_centerLocation.latitude, _centerLocation.longitude),
              name: userDetails['name']?.toString() ?? '',
              number: userDetails['mobile']?.toString() ?? ''));
        }
      });

      setState(() {
        locationAllowed = true;
        state = '3';
        _loading = false;
      });
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
    }
  }

  getLocationPermission() async {
    if (permission == geolocs.LocationPermission.denied ||
        permission == geolocs.LocationPermission.deniedForever) {
      if (permission != geolocs.LocationPermission.deniedForever) {
        await perm.Permission.location.request();
      }
      if (serviceEnabled == false) {
        await geolocs.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocs.LocationAccuracy.low);
        // await location.requestService();
      }
    } else if (serviceEnabled == false) {
      await geolocs.Geolocator.getCurrentPosition(
          desiredAccuracy: geolocs.LocationAccuracy.low);
      // await location.requestService();
    }
    setState(() {
      _loading = true;
    });
    getLocs();
  }

  int _bottom = 0;

  GeoHasher geo = GeoHasher();
  popFunction() {
    if (_bottom == 1) {
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    double lat = 0.0144927536231884;
    double lon = 0.0181818181818182;
    double lowerLat = center.latitude - (lat * 1.24);
    double lowerLon = center.longitude - (lon * 1.24);

    double greaterLat = center.latitude + (lat * 1.24);
    double greaterLon = center.longitude + (lon * 1.24);
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
        if (_bottom == 1) {
          setState(() {
            _bottom = 0;
          });
        }
        return popFunction();
      },
      child: Material(
        child: ValueListenableBuilder(
            valueListenable: valueNotifierHome.value,
            builder: (context, value, child) {
              if (_isDarkTheme != isDarkTheme && _controller != null) {
                _controller!.setMapStyle(mapStyle);
                _isDarkTheme = isDarkTheme;
              }
              if (isGeneral == true) {
                isGeneral = false;
                if (lastNotification != latestNotification) {
                  lastNotification = latestNotification;
                  pref.setString('lastNotification', latestNotification);
                  latestNotification = '';
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationPage()));
                  });
                }
              }
              if (userRequestData.isNotEmpty &&
                  userRequestData['is_later'] == 1 &&
                  userRequestData['is_completed'] != 1 &&
                  userRequestData['accepted_at'] != null) {
                Future.delayed(const Duration(seconds: 2), () {
                  if (userRequestData['is_rental'] == true) {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BookingConfirmation(
                                  type: 1,
                                )),
                        (route) => false);
                  } else {
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BookingConfirmation()),
                        (route) => false);
                  }
                });
              }
              return Directionality(
                textDirection: (languageDirection == 'rtl')
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Scaffold(
                  resizeToAvoidBottomInset: false,
                  drawer: NavDrawer(),
                  body: Stack(
                    children: [
                      Container(
                        color: page,
                        height: media.height * 1,
                        width: media.width * 1,
                        child: Column(
                            mainAxisAlignment: (state == '1' || state == '2')
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            children: [
                              (state == '1')
                                  ? Container(
                                      height: media.height * 1,
                                      width: media.width * 1,
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding:
                                            EdgeInsets.all(media.width * 0.05),
                                        width: media.width * 0.6,
                                        height: media.width * 0.3,
                                        decoration: BoxDecoration(
                                            color: page,
                                            boxShadow: [
                                              BoxShadow(
                                                  blurRadius: 5,
                                                  color: Colors.black
                                                      .withOpacity(0.1),
                                                  spreadRadius: 2)
                                            ],
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              languages[choosenLanguage]
                                                  ['text_enable_location'],
                                              style: GoogleFonts.inter(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Container(
                                              alignment: Alignment.centerRight,
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    state = '';
                                                  });
                                                  getLocs();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_ok'],
                                                  style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize:
                                                          media.width * twenty,
                                                      color: buttonColor),
                                                ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    )
                                  : (state == '2')
                                      ? Container(
                                          height: media.height * 1,
                                          width: media.width * 1,
                                          alignment: Alignment.center,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                  child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  SizedBox(
                                                    height: media.width * 0.02,
                                                  ),
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage][
                                                        'text_allowpermission1'],
                                                    size: 25,
                                                    textAlign: TextAlign.center,
                                                    fontweight: FontWeight.w700,
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.03,
                                                  ),
                                                  MyText(
                                                    text: languages[
                                                            choosenLanguage][
                                                        'text_allowpermission2'],
                                                    size: 16,
                                                    textAlign: TextAlign.center,
                                                    fontweight: FontWeight.w400,
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.10,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Container(
                                                        alignment:
                                                            Alignment.center,
                                                        decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: buttonColor
                                                                .withAlpha(70)),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Icon(
                                                            Icons.location_on,
                                                            color: buttonColor,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                          width: media.width *
                                                              0.02),
                                                      MyText(
                                                        text: languages[
                                                                choosenLanguage]
                                                            [
                                                            'text_loc_permission_user'],
                                                        size: 20,
                                                        fontweight:
                                                            FontWeight.w600,
                                                      )
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    height: media.width * 0.12,
                                                  ),
                                                  SizedBox(
                                                    height: Responsive.height(
                                                        25, context),
                                                    width: Responsive.width(
                                                        80, context),
                                                    child: Image.asset(
                                                      'assets/images/map_image.png',
                                                      fit: BoxFit.fill,
                                                    ),
                                                  ),
                                                ],
                                              )),
                                              Container(
                                                  padding: EdgeInsets.all(
                                                      media.width * 0.05),
                                                  child: Button(
                                                      onTap: () async {
                                                        getLocationPermission();
                                                      },
                                                      text: languages[
                                                              choosenLanguage]
                                                          ['text_next']))
                                            ],
                                          ),
                                        )
                                      : (state == '3')
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                SizedBox(
                                                    height: media.height * 1,
                                                    width: media.width * 1,
                                                    child: StreamBuilder<
                                                            DatabaseEvent>(
                                                        stream: fdb.onValue,
                                                        builder: (context,
                                                            AsyncSnapshot<
                                                                    DatabaseEvent>
                                                                event) {
                                                          if (event.hasData) {
                                                            List driverData =
                                                                [];
                                                            event.data!.snapshot
                                                                .children
                                                                // ignore: avoid_function_literals_in_foreach_calls
                                                                .forEach(
                                                                    (element) {
                                                              driverData.add(
                                                                  element
                                                                      .value);
                                                            });
                                                            // ignore: avoid_function_literals_in_foreach_calls
                                                            driverData.forEach(
                                                                (element) {
                                                              if (element['is_active'] ==
                                                                      1 &&
                                                                  element['is_available'] ==
                                                                      true) {
                                                                DateTime dt = DateTime
                                                                    .fromMillisecondsSinceEpoch(
                                                                        element[
                                                                            'updated_at']);

                                                                if (DateTime.now()
                                                                        .difference(
                                                                            dt)
                                                                        .inMinutes <=
                                                                    2) {
                                                                  if (myMarkers
                                                                      .where((e) => e
                                                                          .markerId
                                                                          .toString()
                                                                          .contains(
                                                                              'car${element['id']}'))
                                                                      .isEmpty) {
                                                                    myMarkers.add(
                                                                        Marker(
                                                                      markerId:
                                                                          MarkerId(
                                                                              'car${element['id']}'),
                                                                      rotation: (myBearings[element['id'].toString()] !=
                                                                              null)
                                                                          ? myBearings[
                                                                              element['id'].toString()]
                                                                          : 0.0,
                                                                      position: LatLng(
                                                                          element['l']
                                                                              [
                                                                              0],
                                                                          element['l']
                                                                              [
                                                                              1]),
                                                                      icon: (element['vehicle_type_icon'] ==
                                                                              'taxi')
                                                                          ? pinLocationIcon
                                                                          : bikeIcon,
                                                                    ));
                                                                  } else if (_controller !=
                                                                      null) {
                                                                    if (myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.latitude !=
                                                                            element['l'][
                                                                                0] ||
                                                                        myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.longitude !=
                                                                            element['l'][1]) {
                                                                      var dist = calculateDistance(
                                                                          myMarkers
                                                                              .lastWhere((e) => e.markerId.toString().contains(
                                                                                  'car${element['id']}'))
                                                                              .position
                                                                              .latitude,
                                                                          myMarkers
                                                                              .lastWhere((e) => e.markerId.toString().contains(
                                                                                  'car${element['id']}'))
                                                                              .position
                                                                              .longitude,
                                                                          element['l']
                                                                              [
                                                                              0],
                                                                          element['l']
                                                                              [
                                                                              1]);
                                                                      if (dist >
                                                                              3 &&
                                                                          _controller !=
                                                                              null) {
                                                                        animationController =
                                                                            AnimationController(
                                                                          duration:
                                                                              const Duration(milliseconds: 1500), //Animation duration of marker

                                                                          vsync:
                                                                              this, //From the widget
                                                                        );

                                                                        animateCar(
                                                                            myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.latitude,
                                                                            myMarkers.lastWhere((e) => e.markerId.toString().contains('car${element['id']}')).position.longitude,
                                                                            element['l'][0],
                                                                            element['l'][1],
                                                                            _mapMarkerSink,
                                                                            this,
                                                                            _controller,
                                                                            'car${element['id']}',
                                                                            element['id'],
                                                                            (element['vehicle_type_icon'] == 'taxi') ? pinLocationIcon : bikeIcon);
                                                                      }
                                                                    }
                                                                  }
                                                                }
                                                              } else {
                                                                if (myMarkers
                                                                    .where((e) => e
                                                                        .markerId
                                                                        .toString()
                                                                        .contains(
                                                                            'car${element['id']}'))
                                                                    .isNotEmpty) {
                                                                  myMarkers.removeWhere((e) => e
                                                                      .markerId
                                                                      .toString()
                                                                      .contains(
                                                                          'car${element['id']}'));
                                                                }
                                                              }
                                                            });
                                                          }
                                                          return StreamBuilder<
                                                                  List<Marker>>(
                                                              stream:
                                                                  carMarkerStream,
                                                              builder: (context,
                                                                  snapshot) {
                                                                return GoogleMap(
                                                                  onMapCreated:
                                                                      _onMapCreated,
                                                                  compassEnabled:
                                                                      false,
                                                                  initialCameraPosition:
                                                                      CameraPosition(
                                                                    target:
                                                                        center,
                                                                    zoom: 18.0,
                                                                  ),
                                                                  onCameraMove:
                                                                      (CameraPosition
                                                                          position) {
                                                                    _centerLocation =
                                                                        position
                                                                            .target;
                                                                  },
                                                                  onCameraIdle:
                                                                      () async {
                                                                    setState(
                                                                        () {});
                                                                  },
                                                                  minMaxZoomPreference:
                                                                      const MinMaxZoomPreference(
                                                                          8.0,
                                                                          20.0),
                                                                  myLocationButtonEnabled:
                                                                      false,
                                                                  markers: Set<
                                                                          Marker>.from(
                                                                      myMarkers),
                                                                  buildingsEnabled:
                                                                      false,
                                                                  zoomControlsEnabled:
                                                                      false,
                                                                  myLocationEnabled:
                                                                      true,
                                                                );
                                                              });
                                                        })),
                                                Visibility(
                                                  visible: false,
                                                  child: Positioned(
                                                      top: 0,
                                                      child: Container(
                                                          height:
                                                              media.height * 1,
                                                          width:
                                                              media.width * 1,
                                                          alignment:
                                                              Alignment.center,
                                                          child: (_dropLocationMap ==
                                                                  false)
                                                              ? Column(
                                                                  children: [
                                                                    SizedBox(
                                                                      height: (media.height /
                                                                              2) -
                                                                          media.width *
                                                                              0.08,
                                                                    ),
                                                                    Image.asset(
                                                                      'assets/images/Pick_icon.png',
                                                                      fit: BoxFit.cover,
                                                                        height: 40,
                                                                        width : 40

                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          10,
                                                                    ),
                                                                    InkWell(
                                                                      onTap:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          _pickaddress =
                                                                              true;
                                                                          _dropaddress =
                                                                              false;
                                                                          addAutoFill
                                                                              .clear();
                                                                          _bottom =
                                                                              1;
                                                                        });
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        decoration: BoxDecoration(
                                                                            gradient: LinearGradient(colors: [
                                                                              (isDarkTheme == true) ? const Color(0xff000000) : const Color(0xffFFFFFF),
                                                                              (isDarkTheme == true) ? const Color(0xff808080) : const Color(0xffEFEFEF),
                                                                            ], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                                                                            borderRadius: BorderRadius.circular(5)),
                                                                        width: media.width *
                                                                            0.8,
                                                                        padding:
                                                                            const EdgeInsets.all(5),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: MyText(
                                                                                size: media.width * twelve,
                                                                                fontweight: FontWeight.w600,
                                                                                text: (addressList.where((element) => element.type == 'pickup').isNotEmpty) ? addressList.firstWhere((element) => element.type == 'pickup', orElse: () => AddressList(id: '', address: '', pickup: true, latlng: const LatLng(0.0, 0.0))).address : languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                // maxLines: 1,
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.025,
                                                                    ),
                                                                    if (_lastCenter !=
                                                                        _centerLocation)
                                                                      Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Button(
                                                                            onTap:
                                                                                () async {
                                                                              setState(() {
                                                                                _loading = true;
                                                                              });
                                                                              var val = await geoCoding(_centerLocation.latitude, _centerLocation.longitude);
                                                                              setState(() {
                                                                                if (addressList.where((element) => element.type == 'pickup').isNotEmpty) {
                                                                                  var add = addressList.firstWhere((element) => element.type == 'pickup');
                                                                                  add.address = val?.toString() ?? '';
                                                                                  add.latlng = LatLng(_centerLocation.latitude, _centerLocation.longitude);
                                                                                } else {
                                                                                  addressList.add(AddressList(
                                                                                      id: '1', type: 'pickup', address: val, pickup: true, latlng: LatLng(_centerLocation.latitude, _centerLocation.longitude),
                                                                                      name: userDetails['name']?.toString() ?? '',
                                                                                      number: userDetails['mobile']?.toString() ?? ''));
                                                                                }
                                                                                _lastCenter = _centerLocation;
                                                                                _loading = false;
                                                                              });
                                                                            },
                                                                            text:
                                                                                languages[choosenLanguage]['text_confirm'],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                  ],
                                                                )
                                                              : Image.asset(
                                                                  'assets/images/dropmarker.png'))),
                                                ),
                                                Positioned(
                                                  top: MediaQuery.of(context)
                                                          .padding
                                                          .top +
                                                      20,
                                                  right: Responsive.width(
                                                      5, context),
                                                  child: InkWell(
                                                    onTap: () async {
                                                      if (contactus == false) {
                                                        setState(() {
                                                          contactus = true;
                                                        });
                                                      } else {
                                                        setState(() {
                                                          contactus = false;
                                                        });
                                                      }
                                                    },
                                                    child: Container(
                                                        height:
                                                            media.width * 0.12,
                                                        width:
                                                            media.width * 0.12,
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              contactus == true
                                                                  ? white
                                                                  : buttonColor,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          contactus == true
                                                              ? Icons.close
                                                              : Icons
                                                                  .support_agent_rounded,
                                                          color:
                                                              contactus == true
                                                                  ? buttonColor
                                                                  : white,
                                                          size: media.width *
                                                              0.08,
                                                        )),
                                                  ),
                                                ),
                                                (contactus == true)
                                                    ? Positioned(
                                                        right: Responsive.width(
                                                            5, context),
                                                        top: Responsive.height(
                                                            13, context),
                                                        child: InkWell(
                                                          onTap: () {
                                                            print('object');
                                                          },
                                                          child: Container(
                                                              margin: EdgeInsets
                                                                  .only(
                                                                      top: 10),
                                                              child: Column(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  InkWell(
                                                                    onTap: () {
                                                                      makingPhoneCall(
                                                                          userDetails[
                                                                              'contact_us_mobile1']);
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      height: media
                                                                              .width *
                                                                          0.12,
                                                                      width: media
                                                                              .width *
                                                                          0.12,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color:
                                                                            buttonColor,
                                                                      ),
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      child:
                                                                          Icon(Icons.call,
                                                                        size: media.width *
                                                                            0.065,
                                                                        color:
                                                                            textColor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  InkWell(
                                                                    onTap:
                                                                        () async {
                                                                         var whatsappUrl =
                                                                           "whatsapp://send?phone=${userDetails['contact_us_mobile1']}";
                                                                      String
                                                                          url =
                                                                          "https://wa.me/${userDetails['contact_us_mobile1']}/?text=''}";
                                                                      if (await canLaunch(
                                                                          url)) {
                                                                        await launch(
                                                                            url);
                                                                      } else {
                                                                        ScaffoldMessenger.of(context)
                                                                            .showSnackBar(SnackBar(
                                                                          content:
                                                                              Text("WhatsApp not installed"),
                                                                        ));
                                                                      }
                                                                      // canLaunch(
                                                                      //   //       whatsappUrl)
                                                                      //   //   .then(
                                                                      //   //       (canLaunchWhatsApp) {
                                                                      //   // if (canLaunchWhatsApp) {
                                                                      //   //   launch(
                                                                      //   //       whatsappUrl);
                                                                      //   // } else {
                                                                      //   //   ScaffoldMessenger.of(context)
                                                                      //   //       .showSnackBar(SnackBar(
                                                                      //   //     content:
                                                                      //   //         Text("WhatsApp not installed"),
                                                                      //   //   ));
                                                                      //   // }
                                                                      //});
                                                                      // launchUrl(
                                                                      //     Uri.parse(whatsappUrl));
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      height: media
                                                                              .width *
                                                                          0.12,
                                                                      width: media
                                                                              .width *
                                                                          0.12,
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        shape: BoxShape
                                                                            .circle,
                                                                        color:
                                                                            buttonColor,
                                                                      ),
                                                                      alignment:
                                                                          Alignment
                                                                              .center,
                                                                      child: Icon(
                                                                          Icons.message_rounded,
                                                                          size: media.width *
                                                                              0.08,
                                                                          color:
                                                                              textColor),
                                                                    ),
                                                                  ),
                                                                  SizedBox(
                                                                    height: 10,
                                                                  ),
                                                                  InkWell(
                                                                    onTap: () {
                                                                      makingPhoneCall(
                                                                          '129');
                                                                    },
                                                                    child: Container(
                                                                        height: media.width * 0.12,
                                                                        width: media.width * 0.12,
                                                                        decoration: BoxDecoration(
                                                                          shape:
                                                                              BoxShape.circle,
                                                                          color:
                                                                              buttonColor,
                                                                        ),
                                                                        alignment: Alignment.center,
                                                                        child: Image(height: media.width * 0.08, width: media.width * 0.08, image: AssetImage('assets/images/emergency_icon.png'))),
                                                                  )
                                                                ],
                                                              )),
                                                        ),
                                                      )
                                                    : Container(),
                                                (_bottom == 0)
                                                    ? Positioned(
                                                        top: MediaQuery.of(
                                                                    context)
                                                                .padding
                                                                .top +
                                                            20,
                                                        child: SizedBox(
                                                          width:
                                                              media.width * 0.9,
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            children: [
                                                              StatefulBuilder(
                                                                  builder: (context,
                                                                      setState) {
                                                                return InkWell(
                                                                  onTap: () {
                                                                    Scaffold.of(
                                                                            context)
                                                                        .openDrawer();
                                                                  },
                                                                  child:
                                                                      Container(
                                                                          height: media.width *
                                                                              0.11,
                                                                          width: media.width *
                                                                              0.11,
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            shape:
                                                                                BoxShape.circle,
                                                                            color:
                                                                                buttonColor,
                                                                          ),
                                                                          alignment: Alignment
                                                                              .center,
                                                                          child: Icon(
                                                                              Icons.menu,
                                                                              size: media.width * 0.07,
                                                                              color: textColor)),
                                                                );
                                                              }),
                                                              SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.02,
                                                              ),
                                                              (banners.isNotEmpty)
                                                                  ? SizedBox(
                                                                      width: media
                                                                              .width *
                                                                          0.77,
                                                                      height: media
                                                                              .width *
                                                                          0.15,
                                                                      child:
                                                                          const BannerImage())
                                                                  : Container(),
                                                            ],
                                                          ),
                                                        ))
                                                    : Container(),
                                                Positioned(
                                                    bottom:
                                                        20 + media.width * 0.43,
                                                    child: SizedBox(
                                                      width: media.width * 0.9,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          (userDetails[
                                                                      'show_rental_ride'] ==
                                                                  true)
                                                              ? Button(
                                                                  onTap: () {
                                                                    if (addressList
                                                                        .isNotEmpty) {
                                                                      Navigator.pushAndRemoveUntil(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                              builder: (context) => BookingConfirmation(
                                                                                    type: 1,
                                                                                  )),
                                                                          (route) => false);
                                                                    }
                                                                  },
                                                                  text: languages[
                                                                          choosenLanguage]
                                                                      [
                                                                      'text_rental'],
                                                                )
                                                              : Container(),
                                                          InkWell(
                                                            onTap: () async {
                                                              if (locationAllowed ==
                                                                  true) {
                                                                if (currentLocation !=
                                                                    null) {
                                                                  _controller?.animateCamera(
                                                                      CameraUpdate.newLatLngZoom(
                                                                          currentLocation,
                                                                          18.0));
                                                                  center =
                                                                      currentLocation;
                                                                } else {
                                                                  _controller?.animateCamera(
                                                                      CameraUpdate.newLatLngZoom(
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
                                                                  await geolocs
                                                                          .Geolocator
                                                                      .getCurrentPosition(
                                                                          desiredAccuracy: geolocs
                                                                              .LocationAccuracy
                                                                              .low);
                                                                  if (await geolocs
                                                                      .GeolocatorPlatform
                                                                      .instance
                                                                      .isLocationServiceEnabled()) {
                                                                    setState(
                                                                        () {
                                                                      _locationDenied =
                                                                          true;
                                                                    });
                                                                  }
                                                                }
                                                              }
                                                            },
                                                            child: Container(
                                                              height:
                                                                  media.width *
                                                                      0.1,
                                                              width:
                                                                  media.width *
                                                                      0.1,
                                                              decoration: BoxDecoration(
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
                                                                  color: white,
                                                                  shape: BoxShape
                                                                      .circle),
                                                              child: Icon(
                                                                  Icons
                                                                      .near_me_outlined,
                                                                  color: black),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )),
                                                Positioned(
                                                    bottom: 0,
                                                    child: GestureDetector(
                                                      onPanUpdate: (val) {
                                                        if (val.delta.dy > 0) {
                                                          setState(() {
                                                            _bottom = 0;
                                                            addAutoFill.clear();
                                                            _pickaddress =
                                                                false;
                                                            _dropaddress =
                                                                false;
                                                          });
                                                        }
                                                        if (val.delta.dy < 0) {
                                                          setState(() {
                                                            _bottom = 1;
                                                          });
                                                        }
                                                      },
                                                      child: Container(
                                                        padding: (_bottom == 1)
                                                            ? EdgeInsets.fromLTRB(
                                                                media.width *
                                                                    0.05,
                                                                media.width *
                                                                        0.03 +
                                                                    MediaQuery.of(
                                                                            context)
                                                                        .padding
                                                                        .top,
                                                                media
                                                                        .width *
                                                                    0.05,
                                                                0)
                                                            : EdgeInsets.only(
                                                                left: media
                                                                        .width *
                                                                    0.05,
                                                                right: media
                                                                        .width *
                                                                    0.05),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              darkModeDialogColor,
                                                          borderRadius: (_bottom ==
                                                                  0)
                                                              ? const BorderRadius
                                                                      .only(
                                                                  topLeft: Radius
                                                                      .circular(
                                                                          30),
                                                                  topRight: Radius
                                                                      .circular(
                                                                          30))
                                                              : BorderRadius
                                                                  .circular(0),
                                                        ),
                                                        height: (_bottom == 0)
                                                            ? userDetails['show_ride_without_destination']
                                                                        .toString() ==
                                                                    '1'
                                                                ? media.width *
                                                                    0.55
                                                                : media.width *
                                                                    0.35
                                                            : media.height * 1,
                                                        width: media.width * 1,
                                                        child: Padding(
                                                          padding: EdgeInsets.only(
                                                              left: Responsive
                                                                  .width(0,
                                                                      context)),
                                                          child: Column(
                                                            children: [
                                                              (_bottom == 1)
                                                                  ? Column(
                                                                      children: [
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.02,
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            InkWell(
                                                                              onTap: () {
                                                                                setState(() {
                                                                                  _bottom = 0;
                                                                                });
                                                                              },
                                                                              child: IosBackButton(),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.1,
                                                                        ),
                                                                      ],
                                                                    )
                                                                  : Container(),
                                                              (_bottom == 1)
                                                                  ? Container(
                                                                      height: media
                                                                              .width *
                                                                          0.25,
                                                                      width: media
                                                                              .width *
                                                                          0.9,
                                                                      padding: EdgeInsets.fromLTRB(
                                                                          media.width *
                                                                              0.02,
                                                                          media.width *
                                                                              0.02,
                                                                          media.width *
                                                                              0.02,
                                                                          0),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(media.width *
                                                                                0.02),
                                                                        color:
                                                                            page,
                                                                      ),
                                                                      child:
                                                                          Column(
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.start,
                                                                        children: [
                                                                          SizedBox(
                                                                            height:
                                                                                media.width * 0.02,
                                                                          ),
                                                                          Container(width: media.width * 0.86,
                                                                          padding: EdgeInsets.symmetric(horizontal: media.width * 0.03, vertical: media.width * 0.01),
                                                                          decoration: BoxDecoration(
                                                                          borderRadius: BorderRadius.circular(media.width * 0.03),
                                                                          color: darkModeSecContainer,
                                                                  ),
                                                                  child: SizedBox(
                                                                    height:
                                                                    media.width * 0.1,
                                                                    child:
                                                                    Column(
                                                                      children: [
                                                                        Expanded(
                                                                          child: Row(
                                                                            children: [
                                                                              Container(
                                                                                height: media.width * 0.04,
                                                                                width: media.width * 0.04,
                                                                                        alignment: Alignment.center,
                                                                                        decoration: BoxDecoration(
                                                                                            image: DecorationImage(
                                                                                                image: AssetImage(
                                                                                          'assets/images/locationMarker.png',
                                                                                        ))),
                                                                                      ),
                                                                                      SizedBox(width: media.width * 0.02),
                                                                                      (_pickaddress == true && _bottom == 1)
                                                                                          ? Expanded(
                                                                                              child: TextField(
                                                                                                  autofocus: true,
                                                                                                  decoration: InputDecoration(
                                                                                                    // contentPadding: (languageDirection == 'rtl') ? EdgeInsets.only(bottom: media.width * 0.035) : EdgeInsets.only(bottom: media.width * 0.047),
                                                                                                    hintText: languages[choosenLanguage]['text_4letterpickup'],
                                                                                                    hintStyle: choosenLanguage == 'ar'
                                                                                                        ? GoogleFonts.cairo(
                                                                                                            fontSize: media.width * twelve,
                                                                                                            color: textColor.withOpacity(0.4),
                                                                                                          )
                                                                                                        : GoogleFonts.inter(
                                                                                                            fontSize: 14,
                                                                                                            fontWeight: FontWeight.w500,
                                                                                                            color: textColor.withOpacity(0.4),
                                                                                                          ),
                                                                                                    border: InputBorder.none,
                                                                                                  ),
                                                                                                  style: choosenLanguage == 'ar' ? GoogleFonts.cairo(fontSize: media.width * fourteen, color: (isDarkTheme == true) ? Colors.white : textColor) : GoogleFonts.inter(fontSize: media.width * fourteen, color: (isDarkTheme == true) ? Colors.white : textColor),
                                                                                                  maxLines: 1,
                                                                                                  onChanged: (val) {
                                                                                                    _debouncer.run(() {
                                                                                                      if (val.length >= 4) {
                                                                                                        if (storedAutoAddress.where((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase())).isNotEmpty) {
                                                                                                          addAutoFill.removeWhere((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase()) == false);
                                                                                                          storedAutoAddress.where((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase())).forEach((element) {
                                                                                                            addAutoFill.add(element);
                                                                                                          });
                                                                                                          valueNotifierHome.incrementNotifier();
                                                                                                        } else {
                                                                                                          getAutoAddress(val, _sessionToken, center.latitude, center.longitude);
                                                                                                        }
                                                                                                      } else {
                                                                                                        setState(() {
                                                                                                          addAutoFill.clear();
                                                                                                        });
                                                                                                      }
                                                                                                    });
                                                                                                  }),
                                                                                            )
                                                                                          : Expanded(
                                                                                              child: InkWell(
                                                                                                onTap: () {
                                                                                                  setState(() {
                                                                                                    _dropaddress = false;
                                                                                                    _pickaddress = true;
                                                                                                  });
                                                                                                },
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                  children: [
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.55,
                                                                                                      child: MyText(
                                                                                                        text: (addressList.where((element) => element.type == 'pickup').isNotEmpty) ? addressList.firstWhere((element) => element.type == 'pickup', orElse: () => AddressList(id: '', address: '', pickup: true, latlng: const LatLng(0.0, 0.0))).address : languages[choosenLanguage]['text_4letterpickup'],
                                                                                                        size: media.width * fourteen,
                                                                                                        color: textColor,
                                                                                                        maxLines: 1,
                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  height: 5,
                                                                                ),
                                                                                Container(
                                                                                  width: media.width * 0.725,
                                                                                  height: 1,
                                                                                  color: darkModeBorderColor.withAlpha(100),
                                                                                )
                                                                              ],
                                                                            ),
                                                                  )),
                                                                          SizedBox(
                                                                            height:
                                                                            media.width * 0.02,
                                                                          ),
                                                                          SizedBox(
                                                                            height:
                                                                            media.width * 0.07,
                                                                            child:
                                                                            Column(
                                                                              children: [
                                                                                Expanded(
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Icon(
                                                                                        Icons.place,
                                                                                        size: media.width * 0.05,
                                                                                        color: white,
                                                                                      ),
                                                                                      SizedBox(width: media.width * 0.02),
                                                                                      (_dropaddress == true && _bottom == 1)
                                                                                          ? Expanded(
                                                                                              child: TextField(
                                                                                                  focusNode: dropLocFocusNode,
                                                                                                  autofocus: true,
                                                                                                  decoration: InputDecoration(
                                                                                                    contentPadding: (languageDirection == 'rtl') ? EdgeInsets.only(bottom: media.width * 0.035) : EdgeInsets.only(bottom: media.width * 0.03),
                                                                                                    border: InputBorder.none,
                                                                                                    hintText: languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                                    hintStyle: choosenLanguage == 'ar'
                                                                                                        ? GoogleFonts.cairo(
                                                                                                            fontSize: media.width * twelve,
                                                                                                            color: textColor.withOpacity(0.4),
                                                                                                          )
                                                                                                        : GoogleFonts.inter(
                                                                                                            fontSize: 14,
                                                                                                            fontWeight: FontWeight.w500,
                                                                                                            color: textColor.withOpacity(0.4),
                                                                                                          ),
                                                                                                  ),
                                                                                                  style: choosenLanguage == 'ar' ? GoogleFonts.cairo(fontSize: media.width * fourteen, color: (isDarkTheme == true) ? Colors.white : textColor) : GoogleFonts.inter(fontSize: media.width * fourteen, color: (isDarkTheme == true) ? Colors.white : textColor),
                                                                                                  maxLines: 1,
                                                                                                  onChanged: (val) {
                                                                                                    _debouncer.run(() {
                                                                                                      if (val.length >= 4) {
                                                                                                        getAutoAddress(val, _sessionToken, center.latitude, center.longitude);
                                                                                                      } else {
                                                                                                        setState(() {
                                                                                                          addAutoFill.clear();
                                                                                                        });
                                                                                                      }
                                                                                                    });
                                                                                                  }),
                                                                                            )
                                                                                          : Expanded(
                                                                                              child: InkWell(
                                                                                                onTap: () {
                                                                                                  setState(() {
                                                                                                    _dropaddress = true;
                                                                                                    _pickaddress = false;
                                                                                                  });
                                                                                                },
                                                                                                child: Row(
                                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                  children: [
                                                                                                    SizedBox(
                                                                                                      width: media.width * 0.55,
                                                                                                      child: MyText(
                                                                                                        text: languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                                        size: media.width * fourteen,
                                                                                                        color: (isDarkTheme == true) ? Colors.white : textColor,
                                                                                                        maxLines: 1,
                                                                                                        overflow: TextOverflow.ellipsis,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                            )
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                                SizedBox(
                                                                                  height: 5,
                                                                                ),
                                                                                Container(
                                                                                  width: media.width * 0.725,
                                                                                  height: 1,
                                                                                  color: darkModeBorderColor.withAlpha(100),
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    )
                                                                  : Container(),
                                                              (_bottom == 1)
                                                                  ? InkWell(
                                                                      onTap:
                                                                          () async {
                                                                        setState(
                                                                            () {
                                                                          addAutoFill
                                                                              .clear();
                                                                          _bottom =
                                                                              0;
                                                                        });
                                                                        if (_dropaddress ==
                                                                                true &&
                                                                            addressList.where((element) => element.type == 'pickup').isNotEmpty) {
                                                                          var navigate = await Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(builder: (context) => DropLocation()));
                                                                          if (navigate !=
                                                                              null) {
                                                                            destinationAddress =
                                                                                [];
                                                                            destinationAddress =
                                                                                addressList.where((element) => element.type == 'drop').toList();
                                                                            destinationDropOff =
                                                                                destinationLocation;
                                                                            if (navigate) {
                                                                              // setState(() {
                                                                              //   addressList.removeWhere((element) => element.type == 'drop');
                                                                              // });
                                                                            }
                                                                          }
                                                                        } else {
                                                                          var nav = await Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                  builder: (context) => DropLocation(
                                                                                        from: addressList[0].id,
                                                                                      )));
                                                                          if (nav) {
                                                                            setState(() {
                                                                              _pickaddress = false;
                                                                              _dropaddress = true;
                                                                              addAutoFill.clear();
                                                                              _bottom = 1;
                                                                            });
                                                                          }
                                                                        }
                                                                      },
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.center,
                                                                        children: [
                                                                          Container(
                                                                            alignment:
                                                                                Alignment.center,
                                                                            padding:
                                                                                EdgeInsets.all(2),
                                                                            width:
                                                                                Responsive.width(7, context),
                                                                            height:
                                                                                Responsive.height(3, context),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: buttonColor.withAlpha(50),
                                                                              border: Border.all(color: buttonColor),
                                                                              shape: BoxShape.circle,
                                                                            ),
                                                                            child:
                                                                                Icon(
                                                                              Icons.location_on,
                                                                              color: buttonColor,
                                                                              size: 15,
                                                                            ),
                                                                          ),
                                                                          SizedBox(
                                                                            width:
                                                                                10,
                                                                          ),
                                                                          MyText(
                                                                            text:
                                                                                languages[choosenLanguage]['text_view_on_map'],
                                                                            size:
                                                                                12,
                                                                            fontweight:
                                                                                FontWeight.w600,
                                                                            color:
                                                                                textColor,
                                                                          ),
                                                                        ],
                                                                      ))
                                                                  : Container(),
                                                              SizedBox(
                                                                height: _bottom ==
                                                                            1 &&
                                                                        userDetails['show_ride_without_destination'].toString() ==
                                                                            '1'
                                                                    ? media.width *
                                                                        0.07
                                                                    : 0,
                                                              ),
                                                              (_bottom == 1 &&
                                                                      userDetails['show_ride_without_destination']
                                                                              .toString() ==
                                                                          '1')
                                                                  ? Visibility(
                                                                      visible:
                                                                          !(_bottom ==
                                                                              0),
                                                                      child:
                                                                          Column(
                                                                        children: [
                                                                          Container(
                                                                            width:
                                                                                media.width * 0.8,
                                                                            height:
                                                                                media.width * 0.125,
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              borderRadius: BorderRadius.circular(3000),
                                                                              border: Border.all(color: buttonColor),
                                                                              color: buttonColor.withOpacity(0.2),
                                                                            ),
                                                                            child:
                                                                                Row(
                                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                                              children: [
                                                                                InkWell(
                                                                                  onTap: () {
                                                                                    // if (_dropaddress == true) {
                                                                                    setState(() {
                                                                                      Navigator.pushAndRemoveUntil(
                                                                                          context,
                                                                                          MaterialPageRoute(
                                                                                              builder: (context) => BookingConfirmation(
                                                                                                    type: 2,
                                                                                                  )),
                                                                                          (route) => false);
                                                                                    });

                                                                                    // }
                                                                                  },
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Icon(
                                                                                        Icons.route_sharp,
                                                                                        color: textColor,
                                                                                        size: media.width * thirteen,
                                                                                      ),
                                                                                      SizedBox(
                                                                                        width: media.width * 0.02,
                                                                                      ),
                                                                                      MyText(text: languages[choosenLanguage]['text_ridewithout_destination'], size: media.width * eleven, fontweight: FontWeight.w600, color: textColor),
                                                                                    ],
                                                                                  ),
                                                                                )
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    )
                                                                  : Container(),
                                                              Visibility(
                                                                visible:
                                                                    _bottom ==
                                                                        1,
                                                                child: Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.07,
                                                                    ),
                                                                    MyText(
                                                                      text: languages[
                                                                              choosenLanguage]
                                                                          [
                                                                          'text_saved_place'],
                                                                      size: 20,
                                                                      fontweight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                    SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.05,
                                                                    ),
                                                                    InkWell(
                                                                      onTap:
                                                                          () async {
                                                                        if (_pickaddress ==
                                                                            true) {
                                                                          setState(
                                                                              () {
                                                                            addAutoFill.clear();
                                                                            if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                                                                              addressList.add(AddressList(id: '1', type: 'pickup', pickup: true, address: 'Casablanca', latlng: LatLng(33.589886, -7.603869)));
                                                                            } else {
                                                                              addressList.firstWhere((element) => element.type == 'pickup').address = 'Casablanca';
                                                                              addressList.firstWhere((element) => element.type == 'pickup').latlng = LatLng(33.589886, -7.603869);
                                                                            }
                                                                            _controller?.moveCamera(CameraUpdate.newLatLngZoom(LatLng(33.589886, -7.603869),
                                                                                14.0));

                                                                            _bottom =
                                                                                0;
                                                                          });
                                                                        } else {
                                                                          setState(
                                                                              () {
                                                                            if (addressList.where((element) => element.type == 'drop').isEmpty) {
                                                                              addressList.add(AddressList(id: '2', type: 'drop', address: 'Casablanca', pickup: false, latlng: LatLng(33.589886, -7.603869)));
                                                                            } else {
                                                                              addressList.firstWhere((element) => element.type == 'drop').address = 'Casablanca';
                                                                              addressList.firstWhere((element) => element.type == 'drop').latlng = LatLng(33.589886, -7.603869);
                                                                            }
                                                                            addAutoFill.clear();
                                                                            _bottom =
                                                                                0;
                                                                          });
                                                                          if (addressList.length ==
                                                                              2) {
                                                                            Navigator.pushAndRemoveUntil(
                                                                                context,
                                                                                MaterialPageRoute(builder: (context) => BookingConfirmation()),
                                                                                (route) => false);

                                                                            dropAddress =
                                                                                'Aéroport International de Ouagadougou-Burkina Faso';
                                                                          }
                                                                        }
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        alignment:
                                                                            Alignment.bottomCenter,
                                                                        padding: EdgeInsets.fromLTRB(
                                                                            media.width *
                                                                                0.04,
                                                                            media.width *
                                                                                0.02,
                                                                            0,
                                                                            media.width *
                                                                                0.02),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border(bottom: BorderSide(width: 1.0, color: (isDarkTheme == true) ? textColor.withOpacity(0.2) : textColor.withOpacity(0.1))),
                                                                        ),
                                                                        child:
                                                                            Row(
                                                                          children: [
                                                                            SizedBox(
                                                                                height: media.width * 0.06,
                                                                                width: media.width * 0.06,
                                                                                child: Image.asset(
                                                                                  'assets/images/airport_address.png',
                                                                                  color: textColor,
                                                                                  width: media.width * 0.04,
                                                                                )),
                                                                            SizedBox(
                                                                              width: 10,
                                                                            ),
                                                                            Expanded(
                                                                              child: Column(
                                                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                                                children: [
                                                                                  SizedBox(
                                                                                    child: MyText(
                                                                                      text: 'Airport',
                                                                                      size: 16,
                                                                                      maxLines: 2,
                                                                                      fontweight: FontWeight.w600,
                                                                                    ),
                                                                                  ),
                                                                                  SizedBox(
                                                                                    height: 5,
                                                                                  ),
                                                                                  SizedBox(
                                                                                    width: media.width * 0.8,
                                                                                    child: MyText(
                                                                                      text: 'Aéroport International de Ouagadougou-Burkina Faso',
                                                                                      size: 15,
                                                                                      maxLines: 2,
                                                                                      fontweight: FontWeight.w400,
                                                                                      color: white.withAlpha(70),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                              (favAddress.isNotEmpty &&
                                                                      _bottom ==
                                                                          1 &&
                                                                      addAutoFill
                                                                          .isEmpty)
                                                                  ? Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        SizedBox(
                                                                          width:
                                                                              media.width * 0.9,
                                                                          child:
                                                                              SingleChildScrollView(
                                                                            child:
                                                                                Column(
                                                                              children: [
                                                                                (favAddress.isNotEmpty)
                                                                                    ? Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: favAddress
                                                                                            .asMap()
                                                                                            .map((i, value) {
                                                                                              return MapEntry(
                                                                                                  i,
                                                                                                  (i < 5)
                                                                                                      ? InkWell(
                                                                                                          onTap: () async {
                                                                                                            if (_pickaddress == true) {
                                                                                                              setState(() {
                                                                                                                addAutoFill.clear();
                                                                                                                if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                                                                                                                  addressList.add(AddressList(id: '1', type: 'pickup', pickup: true, address: favAddress[i]['pick_address'], latlng: LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng'])));
                                                                                                                } else {
                                                                                                                  addressList.firstWhere((element) => element.type == 'pickup').address = favAddress[i]['pick_address'];
                                                                                                                  addressList.firstWhere((element) => element.type == 'pickup').latlng = LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']);
                                                                                                                }
                                                                                                                _controller?.moveCamera(CameraUpdate.newLatLngZoom(LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']), 14.0));

                                                                                                                _bottom = 0;
                                                                                                              });
                                                                                                            } else {
                                                                                                              setState(() {
                                                                                                                if (addressList.where((element) => element.type == 'drop').isEmpty) {
                                                                                                                  addressList.add(AddressList(id: '2', type: 'drop', address: favAddress[i]['pick_address'], pickup: false, latlng: LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng'])));
                                                                                                                } else {
                                                                                                                  addressList.firstWhere((element) => element.type == 'drop').address = favAddress[i]['pick_address'];
                                                                                                                  addressList.firstWhere((element) => element.type == 'drop').latlng = LatLng(favAddress[i]['pick_lat'], favAddress[i]['pick_lng']);
                                                                                                                }
                                                                                                                addAutoFill.clear();
                                                                                                                _bottom = 0;
                                                                                                              });
                                                                                                              if (addressList.length == 2) {
                                                                                                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => BookingConfirmation()), (route) => false);

                                                                                                                dropAddress = favAddress[i]['pick_address'];
                                                                                                              }
                                                                                                            }
                                                                                                          },
                                                                                                          child: Container(
                                                                                                            alignment: Alignment.bottomCenter,
                                                                                                            padding: EdgeInsets.fromLTRB(media.width * 0.04, media.width * 0.02, 0, media.width * 0.02),
                                                                                                            decoration: BoxDecoration(
                                                                                                              border: Border(bottom: BorderSide(width: 1.0, color: (isDarkTheme == true) ? textColor.withOpacity(0.2) : textColor.withOpacity(0.1))),
                                                                                                            ),
                                                                                                            child: Row(
                                                                                                              children: [
                                                                                                                SizedBox(
                                                                                                                  height: media.width * 0.06,
                                                                                                                  width: media.width * 0.06,
                                                                                                                  child: (favAddress[i]['address_name'] == 'Home')
                                                                                                                      ? Image.asset(
                                                                                                                          'assets/images/home.png',
                                                                                                                          color: textColor,
                                                                                                                          width: media.width * 0.04,
                                                                                                                        )
                                                                                                                      : (favAddress[i]['address_name'] == 'Work')
                                                                                                                          ? Image.asset(
                                                                                                                              'assets/images/briefcase.png',
                                                                                                                              color: textColor,
                                                                                                                              width: media.width * 0.04,
                                                                                                                            )
                                                                                                                          : Image.asset(
                                                                                                                              'assets/images/navigation.png',
                                                                                                                              color: textColor,
                                                                                                                              width: media.width * 0.04,
                                                                                                                            ),
                                                                                                                ),
                                                                                                                SizedBox(
                                                                                                                  width: 10,
                                                                                                                ),
                                                                                                                Expanded(
                                                                                                                  child: Column(
                                                                                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                                    children: [
                                                                                                                      SizedBox(
                                                                                                                        child: MyText(
                                                                                                                          text: favAddress[i]['address_name'],
                                                                                                                          size: 16,
                                                                                                                          maxLines: 2,
                                                                                                                          fontweight: FontWeight.w600,
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                      SizedBox(
                                                                                                                        height: 5,
                                                                                                                      ),
                                                                                                                      SizedBox(
                                                                                                                        width: media.width * 0.8,
                                                                                                                        child: MyText(
                                                                                                                          text: favAddress[i]['pick_address'],
                                                                                                                          size: 15,
                                                                                                                          maxLines: 2,
                                                                                                                          fontweight: FontWeight.w400,
                                                                                                                          color: white.withAlpha(70),
                                                                                                                        ),
                                                                                                                      ),
                                                                                                                    ],
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ],
                                                                                                            ),
                                                                                                          ),
                                                                                                        )
                                                                                                      : Container());
                                                                                            })
                                                                                            .values
                                                                                            .toList(),
                                                                                      )
                                                                                    : Container(),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    )
                                                                  : Container(),
                                                              (_bottom == 0)
                                                                  ? SizedBox(
                                                                      height: media
                                                                              .width *
                                                                          0.02)
                                                                  : Container(),
                                                              (_bottom == 0)
                                                                  ? Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        SizedBox(
                                                                          height:
                                                                              media.width * 0.08,
                                                                        ),
                                                                        InkWell(
                                                                          onTap:
                                                                              () {
                                                                            if (addressList.where((element) => element.type == 'pickup').isNotEmpty) {
                                                                              setState(() {
                                                                                _pickaddress = false;
                                                                                _dropaddress = true;
                                                                                addAutoFill.clear();
                                                                                _bottom = 1;
                                                                              });
                                                                            }
                                                                          },
                                                                          child:
                                                                              Row(
                                                                            children: [
                                                                              SizedBox(
                                                                                width: 5,
                                                                              ),
                                                                              Container(
                                                                                height: media.width * 0.045,
                                                                                width: media.width * 0.045,
                                                                                alignment: Alignment.center,
                                                                                decoration: BoxDecoration(
                                                                                    image: DecorationImage(
                                                                                        image: AssetImage(
                                                                                  'assets/images/locationMarker.png',
                                                                                ))),
                                                                              ),
                                                                              SizedBox(width: media.width * 0.02),
                                                                              Container(
                                                                                  padding: EdgeInsets.fromLTRB(media.width * 0.03, 0, media.width * 0.03, 0),
                                                                                  height: media.width * 0.09,
                                                                                  width: media.width * 0.8,
                                                                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: white.withOpacity(0.3))), color: darkModeDialogColor),
                                                                                  alignment: Alignment.centerLeft,
                                                                                  child: Row(
                                                                                    children: [
                                                                                      (_dropaddress == true && _bottom == 1)
                                                                                          ? Expanded(
                                                                                              child: TextField(
                                                                                                  autofocus: true,
                                                                                                  decoration: InputDecoration(
                                                                                                    contentPadding: (languageDirection == 'rtl') ? EdgeInsets.only(bottom: media.width * 0.035) : EdgeInsets.only(bottom: media.width * 0.047),
                                                                                                    border: InputBorder.none,
                                                                                                    hintText: languages[choosenLanguage]['text_4lettersforautofill'],
                                                                                                    hintStyle: choosenLanguage == 'ar'
                                                                                                        ? GoogleFonts.cairo(
                                                                                                            fontSize: media.width * twelve,
                                                                                                            color: textColor.withOpacity(0.4),
                                                                                                          )
                                                                                                        : GoogleFonts.inter(
                                                                                                            fontSize: media.width * twelve,
                                                                                                            color: textColor.withOpacity(0.4),
                                                                                                          ),
                                                                                                  ),
                                                                                                  maxLines: 1,
                                                                                                  onChanged: (val) {
                                                                                                    _debouncer.run(() {
                                                                                                      if (val.length >= 4) {
                                                                                                        if (storedAutoAddress.where((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase())).isNotEmpty) {
                                                                                                          addAutoFill.removeWhere((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase()) == false);
                                                                                                          storedAutoAddress.where((element) => element['description'].toString().toLowerCase().contains(val.toLowerCase())).forEach((element) {
                                                                                                            addAutoFill.add(element);
                                                                                                          });
                                                                                                          valueNotifierHome.incrementNotifier();
                                                                                                        } else {
                                                                                                          getAutoAddress(val, _sessionToken, center.latitude, center.longitude);
                                                                                                        }
                                                                                                      } else {
                                                                                                        setState(() {
                                                                                                          addAutoFill.clear();
                                                                                                        });
                                                                                                      }
                                                                                                    });
                                                                                                  }),
                                                                                            )
                                                                                          : Expanded(
                                                                                          child: _AnimatedWhereToText(
                                                                                            media: media,
                                                                                            baseText: languages[choosenLanguage]['text_where_to'],
                                                                                          )),
                                                                                      SizedBox(
                                                                                        width: media.width * 0.025,
                                                                                      ),
                                                                                      // InkWell(
                                                                                      //     onTap: () {
                                                                                      //       // ignore: prefer_is_empty
                                                                                      //       if (addressList.length >= 1) {
                                                                                      //         Navigator.pushAndRemoveUntil(
                                                                                      //             context,
                                                                                      //             MaterialPageRoute(
                                                                                      //                 builder: (context) => BookingConfirmation(
                                                                                      //                       type: 2,
                                                                                      //                     )),
                                                                                      //             (route) => false);
                                                                                      //       }
                                                                                      //     },
                                                                                      //     child: MyText(
                                                                                      //       text: languages[choosenLanguage]['text_skip'],
                                                                                      //       size: media.width * sixteen,
                                                                                      //       color: textColor,
                                                                                      //       fontweight: FontWeight.bold,
                                                                                      //     ))
                                                                                    ],
                                                                                  )),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                        Visibility(
                                                                          visible:
                                                                              _bottom == 0 && userDetails['show_ride_without_destination'].toString() == '1',
                                                                          child:
                                                                              SizedBox(height: Responsive.height(3.5, context)),
                                                                        ),
                                                                        (_bottom == 0 &&
                                                                                userDetails['show_ride_without_destination'].toString() == '1')
                                                                            ? Column(
                                                                                children: [
                                                                                  Container(
                                                                                    width: media.width * 0.8,
                                                                                    height: media.width * 0.125,
                                                                                    decoration: BoxDecoration(
                                                                                      borderRadius: BorderRadius.circular(3000),
                                                                                      border: Border.all(color: buttonColor),
                                                                                      color: buttonColor.withOpacity(0.2),
                                                                                    ),
                                                                                    child: Row(
                                                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                                                      children: [
                                                                                        InkWell(
                                                                                          onTap: () {
                                                                                            // if (_dropaddress == true) {
                                                                                            setState(() {
                                                                                              Navigator.pushAndRemoveUntil(
                                                                                                  context,
                                                                                                  MaterialPageRoute(
                                                                                                      builder: (context) => BookingConfirmation(
                                                                                                            type: 2,
                                                                                                          )),
                                                                                                  (route) => false);
                                                                                            });

                                                                                            // }
                                                                                          },
                                                                                          child: Row(
                                                                                            children: [
                                                                                              Icon(
                                                                                                Icons.route_sharp,
                                                                                                color: textColor,
                                                                                                size: media.width * thirteen,
                                                                                              ),
                                                                                              SizedBox(
                                                                                                width: media.width * 0.02,
                                                                                              ),
                                                                                              MyText(text: languages[choosenLanguage]['text_ride without_destination'], size: media.width * eleven, fontweight: FontWeight.w600, color: textColor),
                                                                                            ],
                                                                                          ),
                                                                                        )
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              )
                                                                            : Container(),
                                                                      ],
                                                                    )
                                                                  : Container(),
                                                              (_bottom == 1)
                                                                  ? Expanded(
                                                                      child:
                                                                          Container(
                                                                      padding: EdgeInsets.all(
                                                                          media.width *
                                                                              0.03),
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        borderRadius:
                                                                            BorderRadius.circular(media.width *
                                                                                0.02),
                                                                        color:
                                                                            page,
                                                                      ),
                                                                      child: SingleChildScrollView(
                                                                          physics: const BouncingScrollPhysics(),
                                                                          child: Column(
                                                                            children: [
                                                                              (addAutoFill.isNotEmpty)
                                                                                  ? Column(
                                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                                      children: addAutoFill
                                                                                          .asMap()
                                                                                          .map((i, value) {
                                                                                            return MapEntry(
                                                                                                i,
                                                                                                (i < 5)
                                                                                                    ? Container(
                                                                                                        padding: EdgeInsets.fromLTRB(0, media.width * 0.04, 0, media.width * 0.04),
                                                                                                        decoration: BoxDecoration(
                                                                                                          border: Border(bottom: BorderSide(width: 1.0, color: (isDarkTheme == true) ? textColor.withOpacity(0.2) : textColor.withOpacity(0.1))),
                                                                                                        ),
                                                                                                        child: Row(
                                                                                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                                          children: [
                                                                                                            SizedBox(
                                                                                                              height: media.width * 0.1,
                                                                                                              width: media.width * 0.1,
                                                                                                              child: Icon(Icons.access_time, color: textColor),
                                                                                                            ),
                                                                                                            InkWell(
                                                                                                              onTap: () async {
                                                                                                                var val = await geoCodingForLatLng(addAutoFill[i]['place_id']);

                                                                                                                if (_pickaddress == true) {
                                                                                                                  setState(() {
                                                                                                                    if (addressList.where((element) => element.type == 'pickup').isEmpty) {
                                                                                                                      addressList.add(AddressList(id: '1', type: 'pickup', pickup: true, address: addAutoFill[i]['description'], latlng: val,
                                                                                                                          name: userDetails['name']?.toString() ?? '',
                                                                                                                          number: userDetails['mobile']?.toString() ?? ''));
                                                                                                                    } else {
                                                                                                                      addressList.firstWhere((element) => element.type == 'pickup').address = addAutoFill[i]['description'];
                                                                                                                      addressList.firstWhere((element) => element.type == 'pickup').latlng = val;
                                                                                                                    }
                                                                                                                  });
                                                                                                                } else {
                                                                                                                  setState(() {
                                                                                                                    if (addressList.where((element) => element.type == 'drop').isEmpty) {
                                                                                                                      addressList.add(AddressList(id: '2', type: 'drop', pickup: false, address: addAutoFill[i]['description'], latlng: val));
                                                                                                                    } else {
                                                                                                                      addressList.firstWhere((element) => element.type == 'drop').address = addAutoFill[i]['description'];
                                                                                                                      addressList.firstWhere((element) => element.type == 'drop').latlng = val;
                                                                                                                    }
                                                                                                                  });
                                                                                                                  if (addressList.length == 2) {
                                                                                                                    navigate();
                                                                                                                  }
                                                                                                                }
                                                                                                                setState(() {
                                                                                                                  addAutoFill.clear();
                                                                                                                  _dropaddress = false;

                                                                                                                  if (_pickaddress == true) {
                                                                                                                    center = val;
                                                                                                                    _controller?.moveCamera(CameraUpdate.newLatLngZoom(val, 14.0));
                                                                                                                  }
                                                                                                                  _bottom = 0;
                                                                                                                });
                                                                                                              },
                                                                                                              child: SizedBox(
                                                                                                                width: media.width * 0.65,
                                                                                                                child: MyText(text: addAutoFill[i]['description'], size: media.width * twelve, maxLines: 2),
                                                                                                              ),
                                                                                                            ),
                                                                                                            (favAddress.length < 4)
                                                                                                                ? InkWell(
                                                                                                                    onTap: () async {
                                                                                                                      if (favAddress.where((e) => e['pick_address'] == addAutoFill[i]['description']).isEmpty) {
                                                                                                                        var val = await geoCodingForLatLng(addAutoFill[i]['place_id']);
                                                                                                                        setState(() {
                                                                                                                          favSelectedAddress = addAutoFill[i]['description'];
                                                                                                                          favLat = val.latitude;
                                                                                                                          favLng = val.longitude;
                                                                                                                          favAddressAdd = true;
                                                                                                                        });
                                                                                                                      }
                                                                                                                    },
                                                                                                                    child: Icon(
                                                                                                                      Icons.bookmark,
                                                                                                                      size: media.width * 0.05,
                                                                                                                      color: favAddress.where((element) => element['pick_address'] == addAutoFill[i]['description']).isNotEmpty ? buttonColor : textColor.withOpacity(0.3),
                                                                                                                    ),
                                                                                                                  )
                                                                                                                : Container()
                                                                                                          ],
                                                                                                        ),
                                                                                                      )
                                                                                                    : Container());
                                                                                          })
                                                                                          .values
                                                                                          .toList(),
                                                                                    )
                                                                                  : Container(),
                                                                            ],
                                                                          )),
                                                                    ))
                                                                  : Container()
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    )),
                                              ],
                                            )
                                          : Container(),
                            ]),
                      ),

                      //add fav address
                      (favAddressAdd == true)
                          ? Positioned(
                              top: 0,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    favAddressAdd = false;
                                  });
                                },
                                child: Container(
                                  height: media.height * 1,
                                  width: media.width * 1,
                                  color: Colors.transparent.withOpacity(0.6),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.fromLTRB(
                                            media.width * 0.05,
                                            media.width * 0.05,
                                            media.width * 0.05,
                                            MediaQuery.of(context)
                                                    .viewInsets
                                                    .bottom +
                                                media.width * 0.05),
                                        width: media.width * 1,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                const BorderRadius.only(
                                                    topLeft:
                                                        Radius.circular(12),
                                                    topRight:
                                                        Radius.circular(12)),
                                            color: page),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                MyText(
                                                  text:
                                                      languages[choosenLanguage]
                                                          ['text_add_address'],
                                                  size: media.width * sixteen,
                                                  fontweight: FontWeight.w600,
                                                ),
                                              ],
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                            Container(
                                              width: media.width * 0.9,
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.2),
                                                        blurRadius: 2,
                                                        spreadRadius: 2)
                                                  ],
                                                  color: topBar),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height: media.width * 0.064,
                                                    width: media.width * 0.064,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: const Color(
                                                                0xffFF0000)
                                                            .withOpacity(0.1)),
                                                    child: Icon(
                                                      Icons.place,
                                                      size: media.width * 0.04,
                                                      color: const Color(
                                                          0xffFF0000),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: media.width * 0.02,
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      favSelectedAddress,
                                                      style: GoogleFonts.inter(
                                                          fontSize:
                                                              media.width *
                                                                  twelve,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: (isDarkTheme ==
                                                                  true)
                                                              ? Colors.black
                                                              : textColor),
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(
                                              height: media.width * 0.025,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                    setState(() {
                                                      favName = 'Home';
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            media.width * 0.05,
                                                            media.width * 0.02,
                                                            media.width * 0.05,
                                                            media.width * 0.02),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: (favName ==
                                                                  'Home')
                                                              ? buttonColor
                                                              : borderLines,
                                                          width: 1.1),
                                                      color: (favName == 'Home')
                                                          ? buttonColor
                                                          : Colors.transparent,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                            Icons.home_outlined,
                                                            size: media.width *
                                                                0.05,
                                                            color: (favName ==
                                                                    'Home')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.01,
                                                        ),
                                                        MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                ['text_home'],
                                                            size: media.width *
                                                                twelve,
                                                            color: (favName ==
                                                                    'Home')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                    setState(() {
                                                      favName = 'Work';
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            media.width * 0.05,
                                                            media.width * 0.02,
                                                            media.width * 0.05,
                                                            media.width * 0.02),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: (favName ==
                                                                  'Work')
                                                              ? buttonColor
                                                              : borderLines,
                                                          width: 1.1),
                                                      color: (favName == 'Work')
                                                          ? buttonColor
                                                          : Colors.transparent,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .work_outline_outlined,
                                                            size: media.width *
                                                                0.05,
                                                            color: (favName ==
                                                                    'Work')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.01,
                                                        ),
                                                        MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                ['text_work'],
                                                            size: media.width *
                                                                twelve,
                                                            color: (favName ==
                                                                    'Work')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    FocusManager
                                                        .instance.primaryFocus
                                                        ?.unfocus();
                                                    setState(() {
                                                      favName = 'Others';
                                                    });
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.fromLTRB(
                                                            media.width * 0.05,
                                                            media.width * 0.02,
                                                            media.width * 0.05,
                                                            media.width * 0.02),
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                          color: (favName ==
                                                                  'Others')
                                                              ? buttonColor
                                                              : borderLines,
                                                          width: 1.1),
                                                      color: (favName ==
                                                              'Others')
                                                          ? buttonColor
                                                          : Colors.transparent,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                            Icons
                                                                .bookmark_outline,
                                                            size: media.width *
                                                                0.05,
                                                            color: (favName ==
                                                                    'Others')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black),
                                                        SizedBox(
                                                          width: media.width *
                                                              0.01,
                                                        ),
                                                        MyText(
                                                            text: 'Create',
                                                            size: media.width *
                                                                twelve,
                                                            color: (favName ==
                                                                    'Others')
                                                                ? (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white
                                                                : (isDarkTheme ==
                                                                        true)
                                                                    ? Colors
                                                                        .white
                                                                    : Colors
                                                                        .black)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            (favName == 'Others')
                                                ? Container(
                                                    margin: EdgeInsets.only(
                                                        top:
                                                            media.width * 0.03),
                                                    padding: EdgeInsets.all(
                                                        media.width * 0.025),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                            color: borderLines,
                                                            width: 1.2)),
                                                    child: TextField(
                                                      decoration: InputDecoration(
                                                          border:
                                                              InputBorder.none,
                                                          hintText: languages[
                                                                  choosenLanguage]
                                                              [
                                                              'text_enterfavname'],
                                                          hintStyle: GoogleFonts
                                                              .inter(
                                                                  fontSize: media
                                                                          .width *
                                                                      twelve,
                                                                  color:
                                                                      hintColor)),
                                                      maxLines: 1,
                                                      onChanged: (val) {
                                                        setState(() {
                                                          favNameText = val;
                                                        });
                                                      },
                                                    ),
                                                  )
                                                : Container(),
                                            SizedBox(
                                              height: media.width * 0.05,
                                            ),
                                            Button(
                                                onTap: () async {
                                                  if (favName == 'Others' &&
                                                      favNameText != '') {
                                                    setState(() {
                                                      _loading = true;
                                                    });
                                                    var val =
                                                        await addFavLocation(
                                                            favLat,
                                                            favLng,
                                                            favSelectedAddress,
                                                            favNameText);
                                                    setState(() {
                                                      _loading = false;
                                                      if (val == true) {
                                                        favLat = '';
                                                        favLng = '';
                                                        favSelectedAddress = '';
                                                        favName = 'Home';
                                                        favNameText = '';
                                                        favAddressAdd = false;
                                                      } else if (val ==
                                                          'logout') {
                                                        navigateLogout();
                                                      }
                                                    });
                                                  } else if (favName ==
                                                          'Home' ||
                                                      favName == 'Work') {
                                                    setState(() {
                                                      _loading = true;
                                                    });
                                                    var val =
                                                        await addFavLocation(
                                                            favLat,
                                                            favLng,
                                                            favSelectedAddress,
                                                            favName);
                                                    setState(() {
                                                      _loading = false;
                                                      if (val == true) {
                                                        favLat = '';
                                                        favLng = '';
                                                        favName = 'Home';
                                                        favSelectedAddress = '';
                                                        favNameText = '';
                                                        favAddressAdd = false;
                                                      } else if (val ==
                                                          'logout') {
                                                        navigateLogout();
                                                      }
                                                    });
                                                  }
                                                },
                                                text: languages[choosenLanguage]
                                                    ['text_confirm'])
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ))
                          : Container(),

                      //driver cancelled request
                      (requestCancelledByDriver == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: media.width * 0.9,
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]
                                                ['text_drivercancelled'],
                                            style: GoogleFonts.inter(
                                                fontSize:
                                                    media.width * fourteen,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () {
                                                setState(() {
                                                  requestCancelledByDriver =
                                                      false;
                                                  userRequestData = {};
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_ok'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      //user cancelled request
                      (cancelRequestByUser == true)
                          ? Positioned(
                              top: 0,
                              child: Container(
                                height: media.height * 1,
                                width: media.width * 1,
                                color: Colors.transparent.withOpacity(0.6),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: media.width * 0.9,
                                      padding:
                                          EdgeInsets.all(media.width * 0.05),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: page),
                                      child: Column(
                                        children: [
                                          Text(
                                            languages[choosenLanguage]?['text_cancelsuccess'] ?? 'Cancelled successfully',
                                            style: GoogleFonts.inter(
                                                fontSize:
                                                    media.width * fourteen,
                                                fontWeight: FontWeight.w600,
                                                color: textColor),
                                          ),
                                          SizedBox(
                                            height: media.width * 0.05,
                                          ),
                                          Button(
                                              onTap: () {
                                                setState(() {
                                                  cancelRequestByUser = false;
                                                  userRequestData = {};
                                                });
                                              },
                                              text: languages[choosenLanguage]
                                                  ['text_ok'])
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      //delete account
                      (deleteAccount == true)
                          ? Positioned(
                              top: 0,
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
                                          padding: EdgeInsets.all(
                                              media.width * 0.05),
                                          width: media.width * 0.9,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color:
                                                      white.withOpacity(0.5)),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              color: darkModeDialogColor),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: Responsive.height(
                                                    3, context),
                                              ),
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_delete_confirm'],
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                    fontSize:
                                                        media.width * fourteen,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              Button(
                                                  onTap: () async {
                                                    setState(() {
                                                      deleteAccount = false;
                                                      _loading = true;
                                                    });
                                                    var result =
                                                        await userDelete();
                                                    if (result == 'success') {
                                                      setState(() {
                                                        Navigator.pushAndRemoveUntil(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const Login()),
                                                            (route) => false);
                                                        userDetails.clear();
                                                      });
                                                    } else if (result ==
                                                        'logout') {
                                                      navigateLogout();
                                                    } else {
                                                      setState(() {
                                                        _loading = false;
                                                        deleteAccount = true;
                                                      });
                                                    }
                                                    setState(() {
                                                      _loading = false;
                                                    });
                                                  },
                                                  text:
                                                      languages[choosenLanguage]
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
                                                  deleteAccount = false;
                                                });
                                              },
                                              child: Icon(Icons.cancel,
                                                  color: textColor)),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      //logout
                      (logout == true)
                          ? Positioned(
                              top: 0,
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
                                          padding: EdgeInsets.all(
                                              media.width * 0.05),
                                          width: media.width * 0.9,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color:
                                                      white.withOpacity(0.5)),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              color: darkModeDialogColor),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: Responsive.height(
                                                    3, context),
                                              ),
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_confirmlogout'],
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                    fontSize:
                                                        media.width * sixteen,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.05,
                                              ),
                                              Button(
                                                  onTap: () async {
                                                    setState(() {
                                                      logout = false;
                                                      _loading = true;
                                                    });
                                                    var result =
                                                        await userLogout();
                                                    if (result == 'success' ||
                                                        result == 'logout') {
                                                      setState(() {
                                                        Navigator.pushAndRemoveUntil(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const Login()),
                                                            (route) => false);
                                                        userDetails.clear();
                                                      });
                                                    } else {
                                                      setState(() {
                                                        _loading = false;
                                                        logout = true;
                                                      });
                                                    }
                                                    setState(() {
                                                      _loading = false;
                                                    });
                                                  },
                                                  text:
                                                      languages[choosenLanguage]
                                                          ['text_confirm'])
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          top: 15,
                                          right: 15,
                                          child: InkWell(
                                              onTap: () {
                                                if (mounted) {
                                                  setState(() {
                                                    logout = false;
                                                  });
                                                }
                                              },
                                              child: Icon(Icons.cancel,
                                                  color: textColor)),
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ))
                          : Container(),
                      // (_locationDenied == true)
                      //     ? Positioned(
                      //         child: Container(
                      //         height: media.height * 1,
                      //         width: media.width * 1,
                      //         color: Colors.transparent.withOpacity(0.6),
                      //         child: Column(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           children: [
                      //             SizedBox(
                      //               width: media.width * 0.9,
                      //               child: Row(
                      //                 mainAxisAlignment: MainAxisAlignment.end,
                      //                 children: [
                      //                   InkWell(
                      //                     onTap: () {
                      //                       setState(() {
                      //                         _locationDenied = false;
                      //                       });
                      //                     },
                      //                     child: Container(
                      //                       height: media.height * 0.05,
                      //                       width: media.height * 0.05,
                      //                       decoration: BoxDecoration(
                      //                         color: page,
                      //                         shape: BoxShape.circle,
                      //                       ),
                      //                       child: Icon(Icons.cancel,
                      //                           color: buttonColor),
                      //                     ),
                      //                   ),
                      //                 ],
                      //               ),
                      //             ),
                      //             SizedBox(height: media.width * 0.025),
                      //             Container(
                      //               padding: EdgeInsets.all(media.width * 0.05),
                      //               width: media.width * 0.9,
                      //               decoration: BoxDecoration(
                      //                   borderRadius: BorderRadius.circular(12),
                      //                   color: page,
                      //                   boxShadow: [
                      //                     BoxShadow(
                      //                         blurRadius: 2.0,
                      //                         spreadRadius: 2.0,
                      //                         color:
                      //                             Colors.black.withOpacity(0.2))
                      //                   ]),
                      //               child: Column(
                      //                 children: [
                      //                   SizedBox(
                      //                       width: media.width * 0.8,
                      //                       child: Text(
                      //                         languages[choosenLanguage]
                      //                             ['text_open_loc_settings'],
                      //                         style: GoogleFonts.inter(
                      //                             fontSize:
                      //                                 media.width * sixteen,
                      //                             color: textColor,
                      //                             fontWeight: FontWeight.w600),
                      //                       )),
                      //                   SizedBox(height: media.width * 0.05),
                      //                   Row(
                      //                     mainAxisAlignment:
                      //                         MainAxisAlignment.spaceBetween,
                      //                     children: [
                      //                       InkWell(
                      //                           onTap: () async {
                      //                             await perm.openAppSettings();
                      //                           },
                      //                           child: Text(
                      //                             languages[choosenLanguage]
                      //                                 ['text_open_settings'],
                      //                             style: GoogleFonts.inter(
                      //                                 fontSize:
                      //                                     media.width * sixteen,
                      //                                 color: buttonColor,
                      //                                 fontWeight:
                      //                                     FontWeight.w600),
                      //                           )),
                      //                       InkWell(
                      //                           onTap: () async {
                      //                             setState(() {
                      //                               _locationDenied = false;
                      //                               _loading = true;
                      //                             });

                      //                             getLocs();
                      //                           },
                      //                           child: Text(
                      //                             languages[choosenLanguage]
                      //                                 ['text_done'],
                      //                             style: GoogleFonts.inter(
                      //                                 fontSize:
                      //                                     media.width * sixteen,
                      //                                 color: buttonColor,
                      //                                 fontWeight:
                      //                                     FontWeight.w600),
                      //                           ))
                      //                     ],
                      //                   )
                      //                 ],
                      //               ),
                      //             )
                      //           ],
                      //         ),
                      //       ))
                      //     : Container(),
                      (_locationDenied == true)
                          ? Positioned(
                              child: Container(
                              height: media.height * 1,
                              width: media.width * 1,
                              color: Colors.transparent.withOpacity(0.6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(
                                        left: media.width * 0.05,
                                        right: media.width * 0.03,
                                        bottom: media.width * 0.05),
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: page,
                                        boxShadow: [
                                          BoxShadow(
                                              blurRadius: 2.0,
                                              spreadRadius: 2.0,
                                              color:
                                                  Colors.black.withOpacity(0.2))
                                        ]),
                                    child: Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                _locationDenied = false;
                                              });
                                            },
                                            child: Container(
                                              height: media.width * 0.1,
                                              width: media.width * 0.1,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: page),
                                              child: const Icon(Icons.cancel),
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        SizedBox(
                                            width: media.width * 0.8,
                                            child: MyText(
                                              text: languages[choosenLanguage]
                                                  ['text_open_loc_settings'],
                                              size: media.width * sixteen,
                                              fontweight: FontWeight.w600,
                                            )),
                                        SizedBox(height: media.width * 0.05),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all<
                                                          Color>(buttonColor),
                                                  shape:
                                                      MaterialStateProperty.all<
                                                          RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                  ),
                                                  minimumSize:
                                                      MaterialStateProperty
                                                          .all<Size>(Size(
                                                              media.width * 0.3,
                                                              media.width *
                                                                  0.12)),
                                                ),
                                                onPressed: () async {
                                                  await perm.openAppSettings();
                                                },
                                                child: MyText(
                                                  text: languages[
                                                          choosenLanguage]
                                                      ['text_open_settings'],
                                                  size: media.width * sixteen,
                                                  fontweight: FontWeight.w600,
                                                )),
                                            ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      MaterialStateProperty.all<
                                                              Color>(
                                                          Color(0xff191B1A)),
                                                  shape:
                                                      MaterialStateProperty.all<
                                                          RoundedRectangleBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                  ),
                                                  minimumSize:
                                                      MaterialStateProperty
                                                          .all<Size>(Size(
                                                              media.width * 0.3,
                                                              media.width *
                                                                  0.12)),
                                                ),
                                                onPressed: () async {
                                                  setState(() {
                                                    _locationDenied = false;
                                                    _loading = true;
                                                  });
                                                },
                                                child: MyText(
                                                  text:
                                                      languages[choosenLanguage]
                                                          ['text_done'],
                                                  color: Colors.white,
                                                  size: media.width * sixteen,
                                                  fontweight: FontWeight.w600,
                                                ))
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ))
                          : Container(),

                      // loader
                      (_loading == true || state == '')
                          ? const Positioned(top: 0, child: Loading())
                          : Container(),
                      (internet == false)
                          ? Positioned(
                              top: 0,
                              child: NoInternet(
                                onTap: () {
                                  setState(() {
                                    internetTrue();
                                    getUserDetails();
                                  });
                                },
                              ))
                          : Container()
                    ],
                  ),
                ),
              );
            }),
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

    myMarkers.add(carMarker);

    mapMarkerSink.add(Set<Marker>.from(myMarkers).toList());

    Tween<double> tween = Tween(begin: 0, end: 1);

    _animation = tween.animate(animationController)
      ..addListener(() async {
        myMarkers
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

        myMarkers.add(carMarker);

        mapMarkerSink.add(Set<Marker>.from(myMarkers).toList());
      });

    //Starting the animation

    animationController.forward();
  }
}

class Debouncer {
  final int milliseconds;
  dynamic action;
  dynamic _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class BannerImage extends StatefulWidget {
  const BannerImage({super.key});

  @override
  State<BannerImage> createState() => _BannerImageState();
}

class _BannerImageState extends State<BannerImage> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  Timer? timer;
  bool end = false;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage == banners.length - 1) {
        end = true;
      } else if (_currentPage == 0) {
        end = false;
      }

      if (end == false) {
        _currentPage++;
      } else {
        _currentPage--;
      }

      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: PageView.builder(
        controller: _pageController,
        itemCount: banners.length,
        itemBuilder: (context, index) {
          return Image.network(
            banners[index]['image'],
            fit: BoxFit.fitWidth,
          );
        },
      ),
    );
  }
}
class _AnimatedWhereToText extends StatefulWidget {
  final Size media;
  final String baseText;

  const _AnimatedWhereToText({
    Key? key,
    required this.media,
    required this.baseText,
  }) : super(key: key);

  @override
  State<_AnimatedWhereToText> createState() => _AnimatedWhereToTextState();
}

class _AnimatedWhereToTextState extends State<_AnimatedWhereToText> {
  final List<String> _extraHints = [
    'Aéroport de Ouagadougou...',
    'Centre commercial Laafi...',
    'Hôpital Yalgado...',
    'Place de la Nation...',
    'Université de Ouaga...',
  ];

  int _currentIndex = 0;
  bool _showBase = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _showBase = !_showBase;
        if (_showBase) {
          _currentIndex = (_currentIndex + 1) % _extraHints.length;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _showBase
        ? widget.baseText
        : _extraHints[_currentIndex];

    return _TypewriterText(
      text: displayText,
      style: GoogleFonts.inter(
        fontSize: widget.media.width * 0.035,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}

class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _TypewriterText({
    Key? key,
    required this.text,
    required this.style,
  }) : super(key: key);

  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> {
  String _displayed = '';
  int _charIndex = 0;
  Timer? _charTimer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(_TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _charTimer?.cancel();
      _displayed = '';
      _charIndex = 0;
      _startTyping();
    }
  }

  void _startTyping() {
    _charTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayed = widget.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _charTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayed,
      style: widget.style,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    );
  }
}