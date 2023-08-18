import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late PaymentMethod paymentMethod;

  void initStripe() {
    Stripe.publishableKey =
        'pk_test_51Ng7jVKrYwwHnx5IEhA3twCkBMkXyKHL7Ja5JVasWxLA3vVuDC2P81b4cTOORNrveFzOyAms5hcriID92H3VGriw00smALu1VH';
  }
  /*
  Future<void> _createPaymentMethod() async {
    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
          params: PaymentMethodParams.card(
              paymentMethodData: PaymentMethodData(
        mandateData: MandateData(),
        shippingDetails: ShippingDetails(address: ""),
        billingDetails: BillingDetails(name: 'John Doe', email: ''),
      )));
      setState(() {
        paymentMethod = paymentMethod;
      });
    } catch (e) {
      print('Error creating payment method: $e');
    }
  }

  Future<void> _subscribeToPlan() async {
    try {
      await Stripe.instance.confirmPaymentMethodSetup(
        paymentMethod.id,
        setupFutureUsage: PaymentIntentFutureUsage.offSession,
      );

      // Call your backend API to subscribe the user to the plan
      // Handle the subscription status and UI accordingly
    } catch (e) {
      print('Error confirming payment method: $e');
    }
  }
  */

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
                // Implement subscription logic here
                // For example, navigate to a payment screen
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
