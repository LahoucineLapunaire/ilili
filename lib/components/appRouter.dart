import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Ilili/components/addPost.dart';
import 'package:Ilili/components/home.dart';
import 'package:Ilili/components/OwnerProfile.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Ilili/components/google_ads.dart';

FirebaseAuth auth = FirebaseAuth.instance;
FirebaseFirestore firestore = FirebaseFirestore.instance;

class AppRouter extends StatefulWidget {
  final int index;
  const AppRouter({super.key, required this.index});

  @override
  _AppRouterState createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _currentIndex = 0;
  BannerAd? bannerAd;
  late CollectionReference<Map<String, dynamic>> usersCollectionRef;

  final List<Widget> _pages = [
    HomePage(),
    const AddPostPage(),
    const OwnerProfilePage(),
  ];

  @override
  void initState() {
    setState(() {
      _currentIndex = widget.index;
      usersCollectionRef = firestore.collection('users');
    });
    super.initState();
    if (!kIsWeb) {
      initGoogleMobileAds();
      createBannerAd();
    }
  }

  Future<InitializationStatus> initGoogleMobileAds() {
    // This function initializes the Google Mobile Ads SDK and returns an InitializationStatus.
    return MobileAds.instance.initialize();
  }

  void createBannerAd() {
    try {
      // Create a BannerAd with specified ad unit ID, request, and size.
      BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            // Banner ad loaded successfully, update the bannerAd state.
            setState(() {
              bannerAd = ad as BannerAd;
            });
          },
          onAdFailedToLoad: (ad, err) {
            // Banner ad failed to load, print an error message and dispose of the ad.
            print('Failed to load a banner ad: ${err.message}');
            ad.dispose();
          },
        ),
      ).load();
    } catch (e) {
      // Handle any exceptions that may occur during banner ad creation.
      print("error banner ad: ${e.toString()}");
    }
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      // If the second tab is tapped (index 1), show the search delegate.
      showSearch(
        context: context,
        delegate: SearchDelegateWidget(usersCollectionRef),
      );
      return;
    }

    setState(() {
      // Update the current index when a tab is tapped.
      _currentIndex = index;
    });
  }

  @override
  void dispose() {
    super.dispose();
    bannerAd?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bannerAd != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: bannerAd!.size.width.toDouble(),
                  height: bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: bannerAd!),
                ),
              ),
            BottomNavigationBar(
              selectedItemColor: const Color(0xFF6A1B9A),
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            )
          ],
        ));
  }
}
