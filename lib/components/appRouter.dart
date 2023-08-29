import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:Ilili/components/addPost.dart';
import 'package:Ilili/components/home.dart';
import 'package:Ilili/components/OwnerProfile.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:Ilili/components/google_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    AddPostPage(),
    OwnerProfilePage(),
  ];

  void initState() {
    if (widget.index != null) {
      setState(() {
        _currentIndex = widget.index;
        usersCollectionRef = firestore.collection('users');
      });
    }
    super.initState();
    if (!kIsWeb) {
      initGoogleMobileAds();
      createBannerAd();
    }
  }

  Future<InitializationStatus> initGoogleMobileAds() {
    // TODO: Initialize Google Mobile Ads SDK
    return MobileAds.instance.initialize();
  }

  void createBannerAd() {
    try {
      BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {
              bannerAd = ad as BannerAd;
            });
          },
          onAdFailedToLoad: (ad, err) {
            print('Failed to load a banner ad: ${err.message}');
            ad.dispose();
          },
        ),
      ).load();
    } catch (e) {
      print("error banner ad: ${e.toString()}");
    }
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      showSearch(
          context: context, delegate: SearchDelegateWidget(usersCollectionRef));
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

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
              selectedItemColor: Color(0xFF6A1B9A),
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              items: [
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
