import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'functions.dart';

// create an instance
FirebaseMessaging messaging = FirebaseMessaging.instance;
FlutterLocalNotificationsPlugin fltNotification =
FlutterLocalNotificationsPlugin();
FlutterLocalNotificationsPlugin rideNotification =
FlutterLocalNotificationsPlugin();
bool isGeneral = false;
String latestNotification = '';
int id = 0;

void notificationTapBackground(NotificationResponse notificationResponse) {
  isGeneral = true;
  valueNotifierHome.incrementNotifier();
}

var androidDetails = const AndroidNotificationDetails(
  '54321',
  'normal_notification',
  enableVibration: true,
  enableLights: true,
  importance: Importance.high,
  playSound: true,
  priority: Priority.high,
  visibility: NotificationVisibility.private,
);

const iosDetails = DarwinNotificationDetails(
    presentAlert: true, presentBadge: true, presentSound: true);

var generalNotificationDetails =
NotificationDetails(android: androidDetails, iOS: iosDetails);

var androiInit =
const AndroidInitializationSettings('@mipmap/ic_launcher');
var iosInit = const DarwinInitializationSettings(
  defaultPresentAlert: true,
  defaultPresentBadge: true,
  defaultPresentSound: true,
);
var initSetting = InitializationSettings(android: androiInit, iOS: iosInit);

Future<void> initMessaging() async {
  await fltNotification.initialize(settings: initSetting,
    onDidReceiveNotificationResponse: notificationTapBackground,
    onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
  );

  await FirebaseMessaging.instance.requestPermission();

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message?.data != null) {
      if (message?.data['push_type'] == 'general') {
        latestNotification = message?.data['message'];
        isGeneral = true;
        valueNotifierHome.incrementNotifier();
      }
    }
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    if (notification != null) {
      if (message.data['push_type'].toString() == 'general') {
        latestNotification = message.data['message'];
        if (message.data['image'] != null && message.data['image'].toString().isNotEmpty && !message.data['image'].toString().endsWith('/')) {
          _showBigPictureNotificationURLGeneral(message.data);
        } else {
          _showGeneralNotification(message.data);
        }
      } else {
        _showRideNotification(message.notification);
      }
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    if (message.data['push_type'].toString() == 'general') {
      latestNotification = message.data['message'];
      isGeneral = true;
      valueNotifierHome.incrementNotifier();
    }
  });
}

Future<String> _downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = await getApplicationDocumentsDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(url));
  final File file = File(filePath);
  await file.writeAsBytes(response.bodyBytes);
  return filePath;
}

Future<Uint8List> _getByteArrayFromUrl(String url) async {
  final http.Response response = await http.get(Uri.parse(url));
  return response.bodyBytes;
}

Future<void> _showBigPictureNotificationURLGeneral(message) async {
  latestNotification = message['message'];
  if (platform == TargetPlatform.android) {
    final ByteArrayAndroidBitmap bigPicture =
    ByteArrayAndroidBitmap(await _getByteArrayFromUrl(message['image']));
    final BigPictureStyleInformation bigPictureStyleInformation =
    BigPictureStyleInformation(bigPicture);
    final AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
      'notification_1',
      'general image notification',
      channelDescription: 'general notification with image',
      styleInformation: bigPictureStyleInformation,
      enableVibration: true,
      enableLights: true,
      importance: Importance.high,
      playSound: true,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );
    final NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);
    await fltNotification.show(
      id: id++,
      title: message['title'],
      body: message['message'],
      notificationDetails: notificationDetails,
    );
  } else {
    final String bigPicturePath = await _downloadAndSaveFile(
        Uri.parse(message['image']).toString(), 'bigPicture.jpg');
    final DarwinNotificationDetails iosNotifDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments: <DarwinNotificationAttachment>[
          DarwinNotificationAttachment(bigPicturePath)
        ]);
    final NotificationDetails notificationDetails =
    NotificationDetails(iOS: iosNotifDetails);
    await fltNotification.show(
      id: id++,
      title: message['title'],
      body: message['message'],
      notificationDetails: notificationDetails,
    );
  }
}

Future<void> _showGeneralNotification(message) async {
  latestNotification = message['message'];
  const AndroidNotificationDetails androidNotificationDetails =
  AndroidNotificationDetails(
    'notification_1',
    'general notification',
    channelDescription: 'general notification',
    enableVibration: true,
    enableLights: true,
    importance: Importance.high,
    playSound: true,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );
  const DarwinNotificationDetails iosNotifDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true);
  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidNotificationDetails, iOS: iosNotifDetails);
  await fltNotification.show(
    id: id++,
    title: message['title'],
    body: message['message'],
    notificationDetails: notificationDetails,
  );
}

Future<void> _showRideNotification(message) async {
  const AndroidNotificationDetails androidNotificationDetails =
  AndroidNotificationDetails(
    'notification_1',
    'ride notification',
    channelDescription: 'ride notification',
    enableVibration: true,
    enableLights: true,
    importance: Importance.high,
    playSound: true,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
  );
  const DarwinNotificationDetails iosNotifDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );
  const NotificationDetails notificationDetails =
  NotificationDetails(android: androidNotificationDetails, iOS: iosNotifDetails);
  await fltNotification.show(
    id: id++,
    title: message?.title ?? '',
    body: message?.body ?? '',
    notificationDetails: notificationDetails,
  );
}