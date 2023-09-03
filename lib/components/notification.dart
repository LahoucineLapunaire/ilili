import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> sendNotificationToTopic(
  String topic,
  String title,
  String body,
  String image,
  Map<dynamic, dynamic> jsonData,
) async {
  // Obtain an access token
  var credential = await obtainCredentials().then((value) {
    return value.accessToken.data;
  });

  // Define the FCM (Firebase Cloud Messaging) endpoint
  const String fcmEndpoint =
      'https://fcm.googleapis.com/v1/projects/ilili-7ebc6/messages:send';

  // Define headers for the HTTP request
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $credential',
  };

  // Prepare the message data
  final data = {
    "message": {
      "topic": topic,
      "notification": {
        "title": title,
        "body": body,
        "image": image,
      },
      "data": jsonData
    }
  };

  print(data);

  // Send the HTTP POST request to FCM
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
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var privateKeyId = prefs.getString('private_key_id') ?? "";
  var privateKey = prefs.getString('private_key') ?? "";

  // Replace escaped newline characters with actual newline characters
  privateKey = privateKey.replaceAll("\\n", "\n");

  var accountCredentials = ServiceAccountCredentials.fromJson({
    "private_key_id": privateKeyId,
    "private_key": privateKey,
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
