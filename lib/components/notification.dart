import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> sendNotificationToTopic(String topic, String title, String body,
    Map<dynamic, dynamic> jsonData) async {
  var credential = await obtainCredentials().then((value) {
    return value.accessToken.data as String;
  });
  final String fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/ilili-7ebc6/messages:send';

  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $credential',
  };

  final data = {
    "message": {
      "topic": topic,
      "notification": {
        "title": title,
        "body": body,
      },
      "data": jsonData
    }
  };

  print(data);

  final response = await http.post(
    Uri.parse(fcmEndpoint),
    headers: headers,
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    print('Notification sent successfully');
  } else {
    print('Failed to send notification. Response: ${response.body}');
  }
}

Future<AccessCredentials> obtainCredentials() async {
  var accountCredentials = ServiceAccountCredentials.fromJson({
    "private_key_id": "edbeba145ad68e0a47dbe51faca57b2068b0b703",
    "private_key":
        "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQCSDT6A4V7i6cnr\nK4SoqDZL8qwAt5zxbiguT6jHTu14e+grEJsozL36YmF2KMiALh7icjRgTW+sBtyq\n85lbPP3suuzgd3s7lxMIGtVNSfcJlzPd4dnTICeh4QS32rltijmnC8SiD/m9XzTQ\nQsFwTAZWKBYA5xLtu23/Ri23Kxhr01s1GBjec/X0pa6g+WIMhe74bV1v0Dp8Qd2M\ndItIxC77r5M7E0du/R1h/NcILTQaQm/1FAi8NJCoal38+KuT48Q15t2BqjuaGxYa\n7aV3aj4kJYH9rQbpd6WN05dJE00IH5wvlWjYPZlErM1OnePOkga5eFKvzB2Y24vy\nSP86P1uhAgMBAAECggEADZTyt4x9xO9FyjtRSlfeOMDX8vcgPqlmTiw1P1edKMOp\nCvwv2aL0lci5VIIlZxoi4B8LtNrupBo9Qh6GJ+BroqydY6Bo0tlROUM5i8bxlLA9\ncAhVN9d5KAojZK+P59pfUyP6hLGkoVItuKJEl9tSCYgPx8S1U2tHJuKRVMPKsRgi\nH4h8ORh60EiMTNPDTei2VaDRMk9BTcszLQZUyYz+YTqbwPPI70V8tel75WuYONhI\nDHKTRKkHbfsPEX9hSC8vnJyHtpLRohKA/kIRvA7uI1QjgR8dyo0P+4n+VASOik45\nvanIlSpjdAAJ0uyqvz4bi0mh5dBWse2G7akQCACwWwKBgQDDcnumecNzZa2DIG2b\na6vdJI0gERiUgEVEL7tfCGl3DVVNvgU2KVqJb+Gts+Lq1HleYYnfbLhZPDHu1tVQ\nslBwb6MAcT28k4yl0g5C0Dwn5xWaOLSYEUX1DPFrD+CGDyb22HduCXOSwFb1UYTr\neRK6pZeTh007X60Viy6actSoXwKBgQC/TQ4qNEUmGB8wbAYcNNsmy31TOnKxN/hG\nGUNLIU0BuYK+e0oDczFf/Vr0R+YpPwsgShwOldotl9fcx6ZbbK07YMZcFUuI1p9y\nqv5tbAeqO4nPpcbOwY87vv0wBkBCKIKGjiSLDi0RhuXi9Bvcd6dLg9XGjaerlaV4\nDde5Ojp7/wKBgEfC/jGm3aO+PpI50uTRCN5+sC6I+Gx2GHiryfFfxlGHHL4ZuhIj\n5vE1mjhMJ1Ivx4xm5deaNKnXF0JpsRMbFbvi0Ye1DITz7B1qXgAcMyo3h9ADaBO5\nq+UI5o932el/IMBbxKYrZDsK0iLq1pIa90x+xoPNlwbo30VcwDTHWtujAoGAVkC6\n60KIDwX/QgjitGMMkLBdQGJxBgCTW5/WXJCWNPncvl++XlHY6EvGb6/fUaeQL63a\neqUMK1R0SqJmGoCklsoqhahAV2FVoRECCHoV9qZDm7FGM0DIgQq7A6U94dZ8C4kZ\nZu0sWuO00SB5U21Lq9u0ToLeH5oocjnjkyty5ScCgYBXfGAqx5OwyDe0L2N7e6ku\n+CUq0OrsOEVpbXFBpawpPdH82rFyWXb5RZT2VLTMWDd+vz7wmiMN3pABQidNmL5q\nTslmLZ7iudmaI3YDAFAK0ww9NccuEs4DFqC2IbotAezXsznDr0eZd7L7kWz6DI9e\nIKlvVFVuE2CYcm+L45Qomg==\n-----END PRIVATE KEY-----\n",
    "client_email":
        "firebase-adminsdk-l17m2@ilili-7ebc6.iam.gserviceaccount.com",
    "client_id": "109835428077305918471",
    "type": "service_account"
  });
  var scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  var client = http.Client();
  AccessCredentials credentials =
      await obtainAccessCredentialsViaServiceAccount(
          accountCredentials, scopes, client);

  client.close();
  return credentials;
}
