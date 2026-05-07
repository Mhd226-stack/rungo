import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import 'package:geolocator/geolocator.dart' as geolocs;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../login/login.dart';
import '../noInternet/noInternet.dart';
import 'booking_confirmation.dart';
import 'map_page.dart';

// ignore: must_be_immutable
class DropLocation extends StatefulWidget {
  dynamic from;
  DropLocation({Key? key, this.from}) : super(key: key);

  @override
  State<DropLocation> createState() => _DropLocationState();
}

class _DropLocationState extends State<DropLocation>
    with WidgetsBindingObserver {
  GoogleMapController? _controller;
  late PermissionStatus permission;
  Location location = Location();
  String _state = '';
  dynamic _lastCenter;
  bool _isLoading = false;
  String sessionToken = const Uuid().v4();
  LatLng _center = const LatLng(41.4219057, -102.0840772);
  LatLng _centerLocation = const LatLng(41.4219057, -102.0840772);
  TextEditingController search = TextEditingController();
  String favNameText = '';
  bool _locationDenied = false;
  bool favAddressAdd = false;
  final _debouncer = Debouncer(milliseconds: 1000);

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    dropAddressConfirmation = '';
    getLocs();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
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
    _controller?.dispose();
    _controller = null;

    super.dispose();
  }

  getLocs() async {
    permission = await location.hasPermission();

    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever) {
      setState(() {
        _state = '3';
        _isLoading = false;
      });
    } else if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      var locs = await geolocs.Geolocator.getLastKnownPosition();
      if (addressList.length != 2 && widget.from == null) {
        if (locs != null) {
          setState(() {
            _center = LatLng(double.parse(locs.latitude.toString()),
                double.parse(locs.longitude.toString()));
            _centerLocation = LatLng(double.parse(locs.latitude.toString()),
                double.parse(locs.longitude.toString()));
          });
        } else {
          var loc = await geolocs.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocs.LocationAccuracy.low);
          setState(() {
            _center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            _centerLocation = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
          });
        }
        var val = await geoCoding(
            _centerLocation.latitude, _centerLocation.longitude);
        setState(() {
          _center = _centerLocation;
          dropAddressConfirmation = val;
        });
      } else if (widget.from != null && widget.from != 'add stop') {
        setState(() {
          _center = addressList[int.parse(widget.from) - 1].latlng;
          _centerLocation = addressList[int.parse(widget.from) - 1].latlng;
          dropAddressConfirmation =
              addressList[int.parse(widget.from) - 1].address;
        });
      } else if (widget.from == 'add stop') {
        if (locs != null) {
          setState(() {
            _center = LatLng(double.parse(locs.latitude.toString()),
                double.parse(locs.longitude.toString()));
            _centerLocation = LatLng(double.parse(locs.latitude.toString()),
                double.parse(locs.longitude.toString()));
          });
        } else {
          var loc = await geolocs.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocs.LocationAccuracy.low);
          setState(() {
            _center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            _centerLocation = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
          });
        }
      } else {
        setState(() {
          _center = addressList.firstWhere((e) => e.type == 'drop').latlng;
          _centerLocation =
              addressList.firstWhere((e) => e.type == 'drop').latlng;
          if (addressList.length >= 2) {
            dropAddressConfirmation = addressList
                .firstWhere((element) => element.type == 'drop')
                .address;
          }
        });
      }

      setState(() {
        _state = '3';
        _isLoading = false;
      });
    }
  }

  Timer? _debounce;

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

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
                child: Container(
                  height: media.height * 1,
                  width: media.width * 1,
                  color: page,
                  child: Stack(
                    children: [
                      SizedBox(
                        height: media.height * 1,
                        width: media.width * 1,
                        child: (_state == '3')
                            ? GoogleMap(
                                onMapCreated: _onMapCreated,
                                initialCameraPosition: CameraPosition(
                                  target: _center,
                                  zoom: 18.0,
                                ),
                                onCameraMove: (CameraPosition position) {
                                  //pick current location
                                  // setState(() {
                                  //make dropAddressConfirmation to have location name of camera position
                                  if (_debounce?.isActive ?? false)
                                    _debounce?.cancel();
                                  _debounce =
                                      Timer(const Duration(milliseconds: 200),
                                          () async {
                                    // var val = await geoCoding(
                                    //     position.target.latitude,
                                    //     position.target.longitude);
                                    // addressList.add(AddressList(
                                    //     id: (addressList.length + 1)
                                    //         .toString(),
                                    //     type: 'drop',
                                    //     address: val,
                                    //     latlng: position.target,
                                    //     pickup: false)
                                    // );
                                    var val = await geoCoding(
                                        _centerLocation.latitude,
                                        _centerLocation.longitude);
                                    setState(() {
                                      _center = _centerLocation;
                                      _lastCenter = _centerLocation;
                                      dropAddressConfirmation = val;
                                      destinationLocation = _centerLocation;
                                      _isLoading = false;
                                    });
                                    // if(mounted){
                                    //   setState(() {
                                    //     _centerLocation = position.target;
                                    //     dropAddressConfirmation = val;
                                    //   });
                                    // }
                                  });
                                  // dropAddressConfirmation = position.target
                                  //     .toString()
                                  //     .replaceAll('LatLng', '');
                                  _centerLocation = position.target;
                                  // });
                                },
                                onCameraIdle: () async {
                                  setState(() {});
                                },
                                minMaxZoomPreference:
                                    const MinMaxZoomPreference(8.0, 20.0),
                                myLocationButtonEnabled: false,
                                buildingsEnabled: false,
                                zoomControlsEnabled: false,
                                myLocationEnabled: true,
                              )
                            : (_state == '2')
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
                                                ['text_loc_permission'],
                                            style: GoogleFonts.inter(
                                                fontSize: media.width * sixteen,
                                                color: textColor,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Container(
                                            alignment: Alignment.centerRight,
                                            child: InkWell(
                                              onTap: () async {
                                                setState(() {
                                                  _state = '';
                                                });
                                                await location
                                                    .requestPermission();
                                                getLocs();
                                              },
                                              child: Text(
                                                languages[choosenLanguage]
                                                    ['text_ok'],
                                                style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.bold,
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
                                : Container(),
                      ),
                      Positioned(
                          child: Container(
                        height: media.height * 1,
                        width: media.width * 1,
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            SizedBox(
                              height: (media.height / 2) -
                                  media.width * 0.0 -
                                  (
                                       Responsive.height(3.48, context)
                                      ),
                            ),
                            // if (_lastCenter != _centerLocation)
                              // Button(
                              //   borderRadius: 3000.0,
                              //   height: Responsive.height(3.5, context),
                              //   width: Responsive.width(30, context),
                              //   onTap: () async {
                              //     log('pressed');
                              //     setState(() {
                              //       _isLoading = true;
                              //     });
                              //     var val = await geoCoding(
                              //         _centerLocation.latitude,
                              //         _centerLocation.longitude);
                              //     setState(() {
                              //       _center = _centerLocation;
                              //       _lastCenter = _centerLocation;
                              //       dropAddressConfirmation = val;
                              //       destinationLocation = _centerLocation;
                              //       _isLoading = false;
                              //     });
                              //     // if (dropAddressConfirmation != '') {
                              //     //   //remove in envato
                              //     //   if (widget.from == null) {
                              //     //     if (addressList
                              //     //         .where((element) =>
                              //     //     element.type == 'drop')
                              //     //         .isEmpty) {
                              //     //       addressList.add(AddressList(
                              //     //           id: (addressList.length + 1)
                              //     //               .toString(),
                              //     //           type: 'drop',
                              //     //           address:
                              //     //           dropAddressConfirmation,
                              //     //           latlng: _center,
                              //     //           pickup: false));
                              //     //     } else {
                              //     //       addressList
                              //     //           .firstWhere(
                              //     //               (element) =>
                              //     //           element.type ==
                              //     //               'drop')
                              //     //           .address =
                              //     //           dropAddressConfirmation;
                              //     //       addressList
                              //     //           .firstWhere((element) =>
                              //     //       element.type == 'drop')
                              //     //           .latlng = _center;
                              //     //     }
                              //     //   } else if (widget.from != null &&
                              //     //       widget.from != 'add stop') {
                              //     //     addressList[
                              //     //     int.parse(widget.from) - 1]
                              //     //         .name = '';
                              //     //     addressList[
                              //     //     int.parse(widget.from) - 1]
                              //     //         .number = '';
                              //     //     addressList[int.parse(widget.from) -
                              //     //         1]
                              //     //         .address =
                              //     //         dropAddressConfirmation;
                              //     //     addressList[
                              //     //     int.parse(widget.from) - 1]
                              //     //         .latlng = _center;
                              //     //     addressList[
                              //     //     int.parse(widget.from) - 1]
                              //     //         .instructions = null;
                              //     //   } else if (widget.from ==
                              //     //       'add stop') {
                              //     //     addressList.add(AddressList(
                              //     //         id: (addressList.length + 1)
                              //     //             .toString(),
                              //     //         type: 'drop',
                              //     //         address:
                              //     //         dropAddressConfirmation,
                              //     //         latlng: _center,
                              //     //         name: '',
                              //     //         number: '',
                              //     //         instructions: null,
                              //     //         pickup: false));
                              //     //   }
                              //     //   Navigator.pop(context, true);
                              //     // }
                              //     // if (addressList.length >= 2 &&
                              //     //     widget.from == null) {
                              //     //   var val =
                              //     //   await Navigator.pushReplacement(
                              //     //       context,
                              //     //       MaterialPageRoute(
                              //     //           builder: (context) =>
                              //     //               BookingConfirmation()));
                              //     //   if (val) {
                              //     //     setState(() {});
                              //     //   }
                              //     // }
                              //   },
                              //   text: languages[choosenLanguage]
                              //       ['text_confirm'],
                              // ),
                              // _lastCenter != _centerLocation
                              //     ?
                              TriangleShape(
                                      color: buttonColor,
                                      width: media.width * 0.07,
                                      height: media.width * 0.08,
                                    )
                              //     :
                              // Image.asset(
                              //         'assets/images/dropmarker.png',
                              //         width: media.width * 0.07,
                              //         height: media.width * 0.08,
                              //         color: widget.from == null
                              //             ? black
                              //             : buttonColor,
                              //       ),
                            // : TriangleShape(
                            //     color: buttonColor,
                            //     width: media.width * 0.07,
                            //     height: media.width * 0.08,
                            //   )
                          ],
                        ),
                      )),
                      Positioned(
                        bottom: 0 + MediaQuery.of(context).viewInsets.bottom,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              margin:
                                  const EdgeInsets.only(right: 20, left: 20),
                              child: InkWell(
                                onTap: () async {
                                  if (locationAllowed == true) {
                                    if (currentLocation != null) {
                                      _controller?.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                              currentLocation, 18.0));
                                      center = currentLocation;
                                    } else {
                                      _controller?.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                              center, 18.0));
                                    }
                                  } else {
                                    if (serviceEnabled == true) {
                                      setState(() {
                                        _locationDenied = true;
                                      });
                                    } else {
                                      // await location.requestService();
                                      await geolocs.Geolocator
                                          .getCurrentPosition(
                                              desiredAccuracy:
                                                  geolocs.LocationAccuracy.low);
                                      if (await geolocs
                                          .GeolocatorPlatform.instance
                                          .isLocationServiceEnabled()) {
                                        setState(() {
                                          _locationDenied = true;
                                        });
                                      }
                                    }
                                  }
                                },
                                child: Container(
                                  height: media.width * 0.1,
                                  width: media.width * 0.1,
                                  decoration: BoxDecoration(boxShadow: [
                                    BoxShadow(
                                      blurRadius: 2,
                                      color: Colors.black.withOpacity(0.2),
                                    )
                                  ], color: white, shape: BoxShape.circle),
                                  child: Icon(Icons.near_me_outlined,
                                      color: black),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: media.width * 0.1,
                            ),
                            Container(
                              width: media.width * 1,
                              padding: EdgeInsets.all(media.width * 0.05),
                              decoration: BoxDecoration(
                                color: darkModeDialogColor,
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(30)),
                              ),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: Responsive.height(2, context),
                                  ),
                                  Container(
                                      padding: EdgeInsets.fromLTRB(
                                          media.width * 0.03,
                                          media.width * 0.01,
                                          media.width * 0.03,
                                          media.width * 0.01),
                                      height: media.width * 0.1,
                                      width: media.width * 0.9,
                                      decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                              media.width * 0.02),
                                          color: darkModeDialogColor),
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                height: media.width * 0.04,
                                                width: media.width * 0.04,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                        opacity: 0.5,
                                                        image: AssetImage(
                                                          'assets/images/locationMarker.png',
                                                        ))),
                                              ),
                                              SizedBox(
                                                  width: media.width * 0.02),
                                              Expanded(
                                                child:
                                                    (dropAddressConfirmation ==
                                                            '')
                                                        ? Text(
                                                            languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_pickdroplocation'],
                                                            style: GoogleFonts.inter(
                                                                fontSize: media
                                                                        .width *
                                                                    twelve,
                                                                color:
                                                                    hintColor),
                                                          )
                                                        : Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              SizedBox(
                                                                width: media
                                                                        .width *
                                                                    0.7,
                                                                child: Text(
                                                                  dropAddressConfirmation,
                                                                  style:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontSize: media
                                                                            .width *
                                                                        twelve,
                                                                    color:
                                                                        textColor,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                              ),
                                                              (favAddress.length <
                                                                      4)
                                                                  ? InkWell(
                                                                      onTap:
                                                                          () async {
                                                                        if (favAddress
                                                                            .where((element) =>
                                                                                element['pick_address'] ==
                                                                                dropAddressConfirmation)
                                                                            .isEmpty) {
                                                                          setState(
                                                                              () {
                                                                            favSelectedAddress =
                                                                                dropAddressConfirmation;
                                                                            favLat =
                                                                                _center.latitude;
                                                                            favLng =
                                                                                _center.longitude;
                                                                            favAddressAdd =
                                                                                true;
                                                                          });
                                                                        }
                                                                      },
                                                                      child: Icon(
                                                                          favAddress.where((element) => element['pick_address'] == dropAddressConfirmation).isEmpty
                                                                              ? Icons
                                                                                  .favorite_outline
                                                                              : Icons
                                                                                  .favorite,
                                                                          size: media.width *
                                                                              0.05,
                                                                          color: (isDarkTheme == true)
                                                                              ? buttonColor
                                                                              : textColor),
                                                                    )
                                                                  : Container()
                                                            ],
                                                          ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 5,
                                          ),
                                          Container(
                                            width: media.width * 0.9,
                                            height: 1,
                                            color: darkModeBorderColor
                                                .withAlpha(100),
                                          )
                                        ],
                                      )),
                                  SizedBox(
                                    height: media.width * 0.05,
                                  ),
                                  Button(
                                      onTap: () async {
                                        if (dropAddressConfirmation != '') {
                                          //remove in envato
                                          if (widget.from == null) {
                                            if (addressList
                                                .where((element) =>
                                                    element.type == 'drop')
                                                .isEmpty) {
                                              addressList.add(AddressList(
                                                  id: (addressList.length + 1)
                                                      .toString(),
                                                  type: 'drop',
                                                  address:
                                                      dropAddressConfirmation,
                                                  latlng: _center,
                                                  pickup: false));
                                            } else {
                                              addressList
                                                      .firstWhere(
                                                          (element) =>
                                                              element.type ==
                                                              'drop')
                                                      .address =
                                                  dropAddressConfirmation;
                                              addressList
                                                  .firstWhere((element) =>
                                                      element.type == 'drop')
                                                  .latlng = _center;
                                            }
                                          } else if (widget.from != null &&
                                              widget.from != 'add stop') {
                                            addressList[
                                                    int.parse(widget.from) - 1]
                                                .name = '';
                                            addressList[
                                                    int.parse(widget.from) - 1]
                                                .number = '';
                                            addressList[int.parse(widget.from) -
                                                        1]
                                                    .address =
                                                dropAddressConfirmation;
                                            addressList[
                                                    int.parse(widget.from) - 1]
                                                .latlng = _center;
                                            addressList[
                                                    int.parse(widget.from) - 1]
                                                .instructions = null;
                                          } else if (widget.from ==
                                              'add stop') {
                                            addressList.add(AddressList(
                                                id: (addressList.length + 1)
                                                    .toString(),
                                                type: 'drop',
                                                address:
                                                    dropAddressConfirmation,
                                                latlng: _center,
                                                name: '',
                                                number: '',
                                                instructions: null,
                                                pickup: false));
                                          }
                                          Navigator.pop(context, true);
                                        }
                                        if (addressList.length >= 2 &&
                                            widget.from == null) {
                                          var val =
                                              await Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          BookingConfirmation()));
                                          if (val) {
                                            setState(() {});
                                          }
                                        }
                                      },
                                      text: languages[choosenLanguage]
                                          ['text_confirm']),
                                  SizedBox(
                                    height: Responsive.height(2, context),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      //autofill address
                      Positioned(
                          top: 0,
                          child: Container(
                            padding: EdgeInsets.fromLTRB(
                                media.width * 0.05,
                                MediaQuery.of(context).padding.top + 12.5,
                                media.width * 0.05,
                                0),
                            width: media.width * 1,
                            height: (addAutoFill.isNotEmpty)
                                ? media.height * 0.6
                                : null,
                            color: (addAutoFill.isEmpty)
                                ? Colors.transparent
                                : page,
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    InkWell(
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: IosBackButton(
                                          width: Responsive.width(9.5, context),
                                          height:
                                              Responsive.width(9.5, context),
                                        )),
                                    SizedBox(
                                      width: Responsive.width(3, context),
                                    ),
                                    Container(
                                      height: media.width * 0.1,
                                      width: media.width * 0.75,
                                      alignment: Alignment.center,
                                      padding: EdgeInsets.fromLTRB(
                                          media.width * 0.05,
                                          0,
                                          media.width * 0.05,
                                          0),
                                      decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                blurRadius: 2)
                                          ],
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                              media.width * 0.05)),
                                      child: Column(
                                        children: [
                                          Expanded(child: SizedBox()),
                                          Expanded(
                                            child: TextField(
                                                controller: search,

                                                autofocus:
                                                    widget.from == 'add stop'
                                                        ? false
                                                        : false,
                                                decoration: InputDecoration(

                                                    contentPadding:
                                                        (languageDirection ==
                                                                'rtl')
                                                            ? EdgeInsets.only(
                                                                bottom:
                                                                    media.width *
                                                                        0.03)
                                                            : EdgeInsets.only(
                                                                bottom:
                                                                    media.width *
                                                                        0.042),
                                                    border: InputBorder.none,
                                                    hintText: languages[choosenLanguage][
                                                        'text_search_location'],
                                                    hintStyle: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        fontSize: 16,
                                                        color: Color(0xff929292))),
                                                style: choosenLanguage == 'ar'
                                                    ? GoogleFonts.cairo(color: textColor)
                                                    : GoogleFonts.inter(
                                                        color: white,
                                                      ),
                                                maxLines: 1,
                                                onChanged: (val) {
                                                  _debouncer.run(() {
                                                    if (val.length >= 4) {
                                                      if (storedAutoAddress
                                                          .where((element) => element[
                                                                  'description']
                                                              .toString()
                                                              .toLowerCase()
                                                              .contains(val
                                                                  .toLowerCase()))
                                                          .isNotEmpty) {
                                                        addAutoFill.removeWhere(
                                                            (element) =>
                                                                element['description']
                                                                    .toString()
                                                                    .toLowerCase()
                                                                    .contains(val
                                                                        .toLowerCase()) ==
                                                                false);
                                                        storedAutoAddress
                                                            .where((element) => element[
                                                                    'description']
                                                                .toString()
                                                                .toLowerCase()
                                                                .contains(val
                                                                    .toLowerCase()))
                                                            .forEach((element) {
                                                          addAutoFill
                                                              .add(element);
                                                        });
                                                        valueNotifierHome
                                                            .incrementNotifier();
                                                      } else {
                                                        getAutoAddress(
                                                            val,
                                                            sessionToken,
                                                            _center.latitude,
                                                            _center.longitude);
                                                      }
                                                    } else if (val.isEmpty) {
                                                      setState(() {
                                                        addAutoFill.clear();
                                                      });
                                                    }
                                                  });
                                                }),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(
                                  height: media.width * 0.05,
                                ),
                                (addAutoFill.isNotEmpty)
                                    ? Container(
                                        height: media.height * 0.45,
                                        padding:
                                            EdgeInsets.all(media.width * 0.02),
                                        width: media.width * 0.9,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                                media.width * 0.05),
                                            color: page),
                                        child: SingleChildScrollView(
                                          child: Column(
                                            children: addAutoFill
                                                .asMap()
                                                .map((i, value) {
                                                  return MapEntry(
                                                      i,
                                                      (i < 7)
                                                          ? Container(
                                                              padding: EdgeInsets
                                                                  .fromLTRB(
                                                                      0,
                                                                      media.width *
                                                                          0.04,
                                                                      0,
                                                                      media.width *
                                                                          0.04),
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Container(
                                                                    height:
                                                                        media.width *
                                                                            0.1,
                                                                    width: media
                                                                            .width *
                                                                        0.1,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color:
                                                                          darkModeSecContainer,
                                                                    ),
                                                                    child: const Icon(
                                                                        Icons
                                                                            .access_time),
                                                                  ),
                                                                  InkWell(
                                                                    onTap:
                                                                        () async {
                                                                      var val = await geoCodingForLatLng(
                                                                          addAutoFill[i]
                                                                              [
                                                                              'place_id']);
                                                                      setState(
                                                                          () {
                                                                        _center =
                                                                            val;
                                                                        dropAddressConfirmation =
                                                                            addAutoFill[i]['description'];

                                                                        _controller?.moveCamera(CameraUpdate.newLatLngZoom(
                                                                            _center,
                                                                            14.0));
                                                                      });
                                                                      FocusManager
                                                                          .instance
                                                                          .primaryFocus
                                                                          ?.unfocus();
                                                                      addAutoFill
                                                                          .clear();
                                                                      search.text =
                                                                          '';
                                                                    },
                                                                    child:
                                                                        Container(
                                                                      alignment:
                                                                          Alignment
                                                                              .centerLeft,
                                                                      width: media
                                                                              .width *
                                                                          0.7,
                                                                      child: Text(
                                                                          addAutoFill[i]
                                                                              [
                                                                              'description'],
                                                                          style: GoogleFonts
                                                                              .inter(
                                                                            fontSize:
                                                                                media.width * twelve,
                                                                            color:
                                                                                textColor,
                                                                          ),
                                                                          maxLines:
                                                                              2),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : Container());
                                                })
                                                .values
                                                .toList(),
                                          ),
                                        ),
                                      )
                                    : Container()
                              ],
                            ),
                          )),

                      //fav address
                      (favAddressAdd == true)
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
                                          padding: EdgeInsets.fromLTRB(
                                              Responsive.width(10, context),
                                              Responsive.height(4, context),
                                              Responsive.width(10, context),
                                              Responsive.height(4, context)),
                                          width: media.width * 0.9,
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: darkModeBorderColor
                                                      .withAlpha(100)),
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                              color: page),
                                          child: Column(
                                            children: [
                                              Text(
                                                languages[choosenLanguage]
                                                    ['text_saveaddressas'],
                                                style: GoogleFonts.inter(
                                                    fontSize: 22.38,
                                                    color: textColor,
                                                    fontWeight:
                                                        FontWeight.w800),
                                              ),
                                              SizedBox(
                                                height: media.width * 0.04,
                                              ),
                                              Text(
                                                favSelectedAddress,
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.inter(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: textColor),
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
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.01),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.height *
                                                                    0.05,
                                                            width: media.width *
                                                                0.05,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    color: white
                                                                        .withAlpha(
                                                                            100),
                                                                    width:
                                                                        1.2)),
                                                            alignment: Alignment
                                                                .center,
                                                            child: (favName ==
                                                                    'Home')
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.03,
                                                                    width: media
                                                                            .width *
                                                                        0.03,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color:
                                                                          buttonColor,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                          ),
                                                          SizedBox(
                                                            width: media.width *
                                                                0.01,
                                                          ),
                                                          Text(
                                                            languages[
                                                                    choosenLanguage]
                                                                ['text_home'],
                                                            style: GoogleFonts.inter(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600),
                                                          )
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
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.01),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.height *
                                                                    0.05,
                                                            width: media.width *
                                                                0.05,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    color: white
                                                                        .withAlpha(
                                                                            100),
                                                                    width:
                                                                        1.2)),
                                                            alignment: Alignment
                                                                .center,
                                                            child: (favName ==
                                                                    'Work')
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.03,
                                                                    width: media
                                                                            .width *
                                                                        0.03,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color:
                                                                          buttonColor,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                          ),
                                                          SizedBox(
                                                            width: media.width *
                                                                0.01,
                                                          ),
                                                          Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  ['text_work'],
                                                              style: GoogleFonts.inter(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600))
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
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.01),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            height:
                                                                media.height *
                                                                    0.05,
                                                            width: media.width *
                                                                0.05,
                                                            decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    color: white
                                                                        .withAlpha(
                                                                            100),
                                                                    width:
                                                                        1.2)),
                                                            alignment: Alignment
                                                                .center,
                                                            child: (favName ==
                                                                    'Others')
                                                                ? Container(
                                                                    height: media
                                                                            .width *
                                                                        0.03,
                                                                    width: media
                                                                            .width *
                                                                        0.03,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      shape: BoxShape
                                                                          .circle,
                                                                      color:
                                                                          buttonColor,
                                                                    ),
                                                                  )
                                                                : Container(),
                                                          ),
                                                          SizedBox(
                                                            width: media.width *
                                                                0.01,
                                                          ),
                                                          Text(
                                                              languages[
                                                                      choosenLanguage]
                                                                  [
                                                                  'text_others'],
                                                              style: GoogleFonts.inter(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600))
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              (favName == 'Others')
                                                  ? Container(
                                                      padding: EdgeInsets.all(
                                                          media.width * 0.025),
                                                      decoration: BoxDecoration(
                                                          color:
                                                              darkModeSecContainer
                                                                  .withAlpha(
                                                                      100),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                          border: Border.all(
                                                              color:
                                                                  darkModeBorderColor
                                                                      .withAlpha(
                                                                          100),
                                                              width: 1.2)),
                                                      child: TextField(
                                                        decoration: InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            hintText: languages[
                                                                    choosenLanguage]
                                                                [
                                                                'text_enterfavname'],
                                                            hintStyle:
                                                                GoogleFonts.inter(
                                                                    fontSize:
                                                                        14,
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
                                                        _isLoading = true;
                                                      });
                                                      var val =
                                                          await addFavLocation(
                                                              favLat,
                                                              favLng,
                                                              favSelectedAddress,
                                                              favNameText);
                                                      setState(() {
                                                        _isLoading = false;
                                                        if (val == true) {
                                                          favLat = '';
                                                          favLng = '';
                                                          favSelectedAddress =
                                                              '';
                                                          favNameText = '';
                                                          favName = 'Home';
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
                                                        _isLoading = true;
                                                      });
                                                      var val =
                                                          await addFavLocation(
                                                              favLat,
                                                              favLng,
                                                              favSelectedAddress,
                                                              favName);
                                                      setState(() {
                                                        _isLoading = false;
                                                        if (val == true) {
                                                          favLat = '';
                                                          favLng = '';
                                                          favSelectedAddress =
                                                              '';
                                                          favNameText = '';
                                                          favName = 'Home';
                                                          favAddressAdd = false;
                                                        } else if (val ==
                                                            'logout') {
                                                          navigateLogout();
                                                        }
                                                      });
                                                    }
                                                  },
                                                  text:
                                                      languages[choosenLanguage]
                                                          ['text_confirm'])
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            height: media.width * 0.1,
                                            width: media.width * 0.1,
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: page),
                                            child: InkWell(
                                              onTap: () {
                                                setState(() {
                                                  favName = '';
                                                  favAddressAdd = false;
                                                });
                                              },
                                              child: const Icon(Icons.cancel),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ))
                          : Container(),

                      (_locationDenied == true)
                          ? Positioned(
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
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            setState(() {
                                              _locationDenied = false;
                                            });
                                          },
                                          child: Container(
                                            height: media.height * 0.05,
                                            width: media.height * 0.05,
                                            decoration: BoxDecoration(
                                              color: page,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(Icons.cancel,
                                                color: buttonColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: media.width * 0.025),
                                  Container(
                                    padding: EdgeInsets.all(media.width * 0.05),
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
                                        SizedBox(
                                            width: media.width * 0.8,
                                            child: Text(
                                              languages[choosenLanguage]
                                                  ['text_open_loc_settings'],
                                              style: GoogleFonts.inter(
                                                  fontSize:
                                                      media.width * sixteen,
                                                  color: textColor,
                                                  fontWeight: FontWeight.w600),
                                            )),
                                        SizedBox(height: media.width * 0.05),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                                onTap: () async {
                                                  await perm.openAppSettings();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_open_settings'],
                                                  style: GoogleFonts.inter(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: buttonColor,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                )),
                                            InkWell(
                                                onTap: () async {
                                                  setState(() {
                                                    _locationDenied = false;
                                                    _isLoading = true;
                                                  });

                                                  getLocs();
                                                },
                                                child: Text(
                                                  languages[choosenLanguage]
                                                      ['text_done'],
                                                  style: GoogleFonts.inter(
                                                      fontSize:
                                                          media.width * sixteen,
                                                      color: buttonColor,
                                                      fontWeight:
                                                          FontWeight.w600),
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

                      //loader
                      (_isLoading == true)
                          ? const Positioned(child: Loading())
                          : Container(),
                      (internet == false)
                          ?

                          //no internet
                          Positioned(
                              top: 0,
                              child: NoInternet(
                                onTap: () {
                                  setState(() {
                                    internetTrue();
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
}
