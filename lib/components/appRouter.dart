import 'package:flutter/material.dart';
import 'package:ilili/components/addPost.dart';
import 'package:ilili/components/home.dart';
import 'package:ilili/components/OwnerProfile.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:ilili/components/google_ads.dart';

class AppRouter extends StatefulWidget {
  @override
  _AppRouterState createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  int _currentIndex = 0;
  BannerAd? bannerAd;

  final List<Widget> _pages = [
    HomePage(),
    AddPostPage(),
    OwnerProfilePage(),
  ];

  void initState() {
    super.initState();
    initGoogleMobileAds();
    createBannerAd();
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
                  icon: Icon(Icons.add),
                  label: 'Add Post',
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
