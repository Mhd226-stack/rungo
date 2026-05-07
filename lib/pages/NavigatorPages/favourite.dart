import 'package:flutter/material.dart';
import 'package:flutter_user/common/responsive.dart';
import '../../functions/functions.dart';
import '../../styles/styles.dart';
import '../../translations/translation.dart';
import '../../widgets/widgets.dart';
import '../loadingPage/loading.dart';
import '../noInternet/noInternet.dart';

class Favorite extends StatefulWidget {
  const Favorite({Key? key}) : super(key: key);

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  bool _isLoading = false;
  bool _deletingAddress = false;
  dynamic _deletingId;
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
                    padding: EdgeInsets.fromLTRB(media.width * 0.05,
                        media.width * 0.05, media.width * 0.05, 0),
                    height: media.height * 1,
                    width: media.width * 1,
                    color: page,
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
                                        ['text_fav_address']
                                    .toString(),
                                size: media.width * twenty,
                                fontweight: FontWeight.w700,
                              ),
                            ),
                            Positioned(
                                child: InkWell(
                                    onTap: () {
                                      Navigator.pop(context);
                                    },
                                    child: IosBackButton())),
                          ],
                        ),
                        Builder(builder: (context) {
                          print(favAddress.toString());
                          return SizedBox(
                            height: media.width * 0.07,
                          );
                        }),
                        (favAddress.isNotEmpty)
                            ? Expanded(
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Column(
                                    children: favAddress
                                        .asMap()
                                        .map((i, value) {
                                          return MapEntry(
                                            i,
                                            Container(
                                              width: media.width * 0.85,
                                              margin: EdgeInsets.only(
                                                  bottom: media.width * 0.08),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                color: darkModeSecContainer,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    margin: EdgeInsets.all(
                                                        media.width * 0.03),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            (favAddress[i][
                                                                        'address_name'] ==
                                                                    'Home')
                                                                ? Icon(
                                                                    Icons.home,
                                                                    size: media
                                                                            .width *
                                                                        0.075,
                                                                    color:
                                                                        textColor)
                                                                : (favAddress[i]
                                                                            [
                                                                            'address_name'] ==
                                                                        'Work')
                                                                    ? Icon(
                                                                        Icons
                                                                            .work,
                                                                        size: media.width *
                                                                            0.065,
                                                                        color:
                                                                            textColor)
                                                                    : Image
                                                                        .asset(
                                                                        'assets/images/navigation.png',
                                                                        color:
                                                                            textColor,
                                                                        width: media.width *
                                                                            0.065,
                                                                      ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.025,
                                                            ),
                                                            MyText(
                                                              text: favAddress[
                                                                      i][
                                                                  'address_name'],
                                                              size:
                                                                  media.width *
                                                                      eighteen,
                                                              fontweight:
                                                                  FontWeight
                                                                      .w400,
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(
                                                          height: media.width *
                                                              0.02,
                                                        ),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .start,
                                                          children: [
                                                            SizedBox(
                                                              width: 5,
                                                            ),
                                                            SizedBox(
                                                              width:
                                                                  media.width *
                                                                      0.7,
                                                              child: MyText(
                                                                text: favAddress[
                                                                        i][
                                                                    'pick_address'],
                                                                size: media
                                                                        .width *
                                                                    twelve,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(
                                                          height: media.width *
                                                              0.15,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Container(
                                                    height: media.width * 0.08,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          const BorderRadius
                                                                  .only(
                                                              bottomLeft: Radius
                                                                  .circular(15),
                                                              bottomRight:
                                                                  Radius
                                                                      .circular(
                                                                          15)),
                                                      color: buttonColor,
                                                    ),
                                                    child: InkWell(
                                                      onTap: () async {
                                                        setState(() {
                                                          _deletingId =
                                                              favAddress[i]
                                                                  ['id'];
                                                          _deletingAddress =
                                                              true;
                                                        });
                                                      },
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .delete_outline_rounded,
                                                            color: (isDarkTheme ==
                                                                    true)
                                                                ? Colors.white
                                                                : buttonColor,
                                                          ),
                                                          SizedBox(
                                                            width: 5,
                                                          ),
                                                          MyText(
                                                            text: languages[
                                                                    choosenLanguage]
                                                                ['text_delete'],
                                                            size: media.width *
                                                                fifteen,
                                                            color: (isDarkTheme ==
                                                                    true)
                                                                ? Colors.white
                                                                : buttonColor,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          );
                                        })
                                        .values
                                        .toList(),
                                  ),
                                ),
                              )
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
                                              ['text_nofav'],
                                          textAlign: TextAlign.center,
                                          fontweight: FontWeight.w600,
                                          size: media.width * sixteen),
                                    ),
                                  ],
                                ),
                              ),
                      ],
                    ),
                  ),

                  //popup for delete address
                  (_deletingAddress == true)
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
                                    padding: EdgeInsets.all(media.width * 0.05),
                                    width: media.width * 0.9,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: white.withOpacity(0.3)),
                                        borderRadius: BorderRadius.circular(30),
                                        color: darkModeDialogColor),
                                    child: Column(
                                      children: [
                                        SizedBox(
                                          height: Responsive.height(4, context),
                                        ),
                                        MyText(
                                          text: languages[choosenLanguage]
                                              ['text_removeFav'],
                                          size: media.width * seventeen,
                                          fontweight: FontWeight.w400,
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
                                              var result =
                                                  await removeFavAddress(
                                                      _deletingId);
                                              if (result == 'success') {
                                                setState(() {
                                                  _deletingAddress = false;
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
                                              _deletingAddress = false;
                                            });
                                          },
                                          child: Icon(
                                            Icons.cancel,
                                            color: textColor,
                                          )))
                                ],
                              )
                            ],
                          ),
                        ))
                      : Container(),

                  //no internet
                  (internet == false)
                      ? Positioned(
                          top: 0,
                          child: NoInternet(onTap: () {
                            setState(() {
                              internetTrue();
                            });
                          }))
                      : Container(),

                  //loader
                  (_isLoading == true)
                      ? const Positioned(child: Loading())
                      : Container()
                ],
              ),
            );
          }),
    );
  }
}
