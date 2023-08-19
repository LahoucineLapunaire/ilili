import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:ilili/components/addPost.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  Map<String, dynamic>? paymentIntent;
  late String currentSecret;

  void initState() {
    super.initState();
    initStripe();
  }

  void initStripe() async {
    Stripe.publishableKey =
        'pk_test_51Ng7jVKrYwwHnx5IEhA3twCkBMkXyKHL7Ja5JVasWxLA3vVuDC2P81b4cTOORNrveFzOyAms5hcriID92H3VGriw00smALu1VH';
    Stripe.stripeAccountId = 'acct_1Ng7jVKrYwwHnx5I';
  }

  Future<void> subscribeToProduct(String productID) async {
    print("_______HERE1________");
    try {
      var customerId = await verifyIfUserExists();
      if (customerId == "") {
        customerId = await createStripeCustomer();
      }
      print("_______HERE2________");
      var currentSecret = await createPaymentIntent(productID, "eur");
      print("_______HERE3________");
      await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
              customerId: customerId,
              paymentIntentClientSecret: currentSecret,
              style: ThemeMode.dark,
              merchantDisplayName: 'ilili'));
      print("_______HERE4________");
      // Step 3: Present Payment Sheet to the user
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      // Handle errors
      print('Subscription Error: $e');
    }
  }

  Future<String> createSubscription(String productID) async {
    try {
      String customerId = await verifyIfUserExists();
      if (customerId == "") {
        customerId = await createStripeCustomer();
      }
      final response = await http
          .post(Uri.parse('https://api.stripe.com/v1/subscriptions'), headers: {
        'Authorization':
            'Bearer sk_test_51Ng7jVKrYwwHnx5IRMKWR2rWO3zEdQD4CLxuNVyxELX498tS3xsDfB2PYdFiH3H1c69FHaHWNzL165inejqhMJ4j00OJThBQC5',
        'Content-Type': 'application/x-www-form-urlencoded'
      }, body: {
        'customer': customerId,
        "items[0][price]": await getPrice(productID),
      });
      print(response.body);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['latest_invoice']['payment_intent']
            ['client_secret'];
      } else {
        throw Exception('Failed to create subscription');
      }
    } catch (e) {
      throw Exception('Error creating subscription: $e');
    }
  }

  Future<String> createPaymentIntent(String product, String currency) async {
    try {
      String price = await getPrice(product);
      Map<String, dynamic> body = {
        'amount': price,
        'currency': currency,
      };
      var response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization':
              'Bearer sk_test_51Ng7jVKrYwwHnx5IRMKWR2rWO3zEdQD4CLxuNVyxELX498tS3xsDfB2PYdFiH3H1c69FHaHWNzL165inejqhMJ4j00OJThBQC5',
          'Content-Type': 'application/x-www-form-urlencoded'
        },
        body: body,
      );
      return json.decode(response.body)['client_secret'];
    } catch (err) {
      throw Exception(err.toString());
    }
  }

  Future<String> getPrice(String product) async {
    try {
      // Replace 'YOUR_STRIPE_SECRET_KEY' with your actual Stripe secret key
      String secretKey =
          'sk_test_51Ng7jVKrYwwHnx5IRMKWR2rWO3zEdQD4CLxuNVyxELX498tS3xsDfB2PYdFiH3H1c69FHaHWNzL165inejqhMJ4j00OJThBQC5';

      // Make request to retrieve the product details
      var productResponse = await http.get(
        Uri.parse('https://api.stripe.com/v1/products/$product'),
        headers: {
          'Authorization': 'Bearer $secretKey',
        },
      );

      var productData = json.decode(productResponse.body);
      print(productData);
      // Get the default price ID from the product details
      var defaultPriceID = productData['default_price'];

      return defaultPriceID;
    } catch (err) {
      print(err.toString());
    }
    return '';
  }

  Future<String> createStripeCustomer() async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/customers'),
        headers: {
          'Authorization':
              'Bearer sk_test_51Ng7jVKrYwwHnx5IRMKWR2rWO3zEdQD4CLxuNVyxELX498tS3xsDfB2PYdFiH3H1c69FHaHWNzL165inejqhMJ4j00OJThBQC5',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          "description": auth.currentUser!.uid.toString(),
          "email": auth.currentUser!.email.toString(),
          "name": auth.currentUser!.displayName.toString(),
        },
      );
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['id'];
      } else {
        throw Exception('Failed to create Stripe customer');
      }
    } catch (e) {
      throw Exception('Error creating Stripe customer: $e');
    }
  }

  Future<String> verifyIfUserExists() async {
    final response = await http.get(
      Uri.parse('https://api.stripe.com/v1/customers'),
      headers: {
        'Authorization':
            'Bearer sk_test_51Ng7jVKrYwwHnx5IRMKWR2rWO3zEdQD4CLxuNVyxELX498tS3xsDfB2PYdFiH3H1c69FHaHWNzL165inejqhMJ4j00OJThBQC5',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    );
    var data = json.decode(response.body);
    data["data"].forEach((element) {
      if (element['description'] == auth.currentUser!.uid.toString()) {
        return element['description'];
      }
    });
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECEFF1),
      appBar: AppBar(
        backgroundColor: Color(0xFF6A1B9A),
        title: Text('Subscription'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Text(
                    'Upgrade to ilili Subscription',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Get more visibility for your posts and a badge next to your name!',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Subscription Benefits:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SubscriptionBenefitItem(
              icon: Icons.visibility,
              text: 'Posts appear more',
            ),
            SubscriptionBenefitItem(
              icon: Icons.verified,
              text: 'Badge "Certified"',
            ),
            SubscriptionBenefitItem(
              icon: Icons.remove_circle,
              text: 'No more ads',
            ),
            SizedBox(height: 25),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all<Color>(Color(0xFF6A1B9A)),
              ),
              onPressed: () {
                subscribeToProduct(
                    "prod_OTMwHxGCZyq9eU"); // Replace with your product ID
              },
              child: Text('Subscribe for €5/month'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionBenefitItem extends StatelessWidget {
  final IconData icon;
  final String text;

  SubscriptionBenefitItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 30),
        SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}
