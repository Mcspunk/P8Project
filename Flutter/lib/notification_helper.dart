import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:meta/meta.dart';
import 'utility.dart';
import 'package:flutter/material.dart';


// Notification types ---------------------------------------------------


//Images
/*Future<NotificationDetails> _image(Image picture) async {
  final picturePath = await saveImage(context, picture);

  final bigPictureStyleInformation = BigPictureStyleInformation(
    'http://kattekoebing.dk/wp-content/uploads/2018/06/kat3.png',
    BitmapSource.FilePath,
  );

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'big text channel id',
    'big text channel name',
    'big text channel description',
    style: AndroidNotificationStyle.BigPicture,
    styleInformation: bigPictureStyleInformation,
  );
  return NotificationDetails(androidPlatformChannelSpecifics, null);
}

Future<NotificationDetails> _icon(BuildContext context, Image icon) async {
  final iconPath = await saveImage(context, icon);

  final androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'big text channel id',
    'big text channel name',
    'big text channel description',
    largeIcon: iconPath,
    largeIconBitmapSource: BitmapSource.FilePath,
  );
  return NotificationDetails(androidPlatformChannelSpecifics, null);
}*/

  NotificationDetails get _multiplePOI {
    final androidChannelSpecifics = AndroidNotificationDetails(
      'channelId', 
      'channelName', 
      'channelDescription',
      ongoing: true,
      importance: Importance.Max,
      priority: Priority.High,
      autoCancel: false,      
    );
    final iOSChannelSpecifics = IOSNotificationDetails();
    return NotificationDetails(androidChannelSpecifics,iOSChannelSpecifics);
  }

  NotificationDetails get _singlePOI {
    final androidChannelSpecifics = AndroidNotificationDetails(
      'channelId', 
      'channelName', 
      'channelDescription',
      ongoing: true,
      importance: Importance.Max,
      priority: Priority.High,
      autoCancel: false,      
    );
    final iOSChannelSpecificss = IOSNotificationDetails();
    return NotificationDetails(androidChannelSpecifics, iOSChannelSpecificss);
  }


  //Notification methods --------------------------------------------------

/* Images
  Future showImageNotification(
  BuildContext context,
  FlutterLocalNotificationsPlugin notification, {
  @required String title,
  @required String body,
  @required Image picture,
  int id = 0,
  }) async =>
    notification.show(id, title, body, await _image(picture));


Future showIconNotification(
  BuildContext context,
  FlutterLocalNotificationsPlugin notification, {
  @required String title,
  @required String body,
  @required Image icon,
  int id = 0,
}) async =>
    notification.show(id, title, body, await _icon(context, icon));
*/

  //TODO -- Method to display notification for mulitple POI
  Future multiplePOINotif (FlutterLocalNotificationsPlugin notification, {
      @required String title,
      @required String body,
      int id = 0
  }) => _showNotification(notification, id: id, title: title, body: body, type: _multiplePOI);

  //test method to display one new POI 
  Future singlePOINotif (
    FlutterLocalNotificationsPlugin notification, {
      @required String title,
      @required String body,
      int id = 0,
    }) => _showNotification(notification, id: id, title: title, body: body, type: _singlePOI);

  // general method to show notifications
  Future _showNotification(    
    FlutterLocalNotificationsPlugin notification, {
      @required String title,
      @required String body,
      @required NotificationDetails type,
      int id,
    }) => notification.show(id,title,body,type);