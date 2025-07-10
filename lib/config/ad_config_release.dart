/// Release AdMob configuration for production IDs
///
/// IMPORTANT: Replace all placeholder values with your actual AdMob IDs
///
/// To get your production AdMob IDs:
/// 1. Go to https://apps.admob.com/
/// 2. Select your app
/// 3. Copy the App ID from the app overview
/// 4. Go to Ad units section and copy each Ad Unit ID
///
/// This file should be added to .gitignore to keep your production IDs private
class AdConfig {
  // Production App ID (Android)
  // Replace with your actual Android App ID from AdMob console
  static const String appId = 'ca-app-pub-YOUR_PUBLISHER_ID~YOUR_APP_ID';

  // Production Ad Unit IDs (Android)
  // Replace with your actual Ad Unit IDs from AdMob console
  static const String interstitialAdUnitId =
      'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_INTERSTITIAL_AD_UNIT_ID';
  static const String bannerAdUnitId =
      'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_BANNER_AD_UNIT_ID';
  static const String rewardedAdUnitId =
      'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_REWARDED_AD_UNIT_ID';
  static const String nativeAdUnitId =
      'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_NATIVE_AD_UNIT_ID';

  // Production iOS IDs (for future use)
  // Replace with your actual iOS App ID and Ad Unit IDs
  static const String iosAppId = 'ca-app-pub-YOUR_PUBLISHER_ID~YOUR_IOS_APP_ID';
  static const String iosInterstitialAdUnitId =
      'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_IOS_INTERSTITIAL_AD_UNIT_ID';
  static const String iosBannerAdUnitId =
      'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_IOS_BANNER_AD_UNIT_ID';
  static const String iosRewardedAdUnitId =
      'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_IOS_REWARDED_AD_UNIT_ID';
  static const String iosNativeAdUnitId =
      'ca-app-pub-YOUR_PUBLISHER_ID/YOUR_IOS_NATIVE_AD_UNIT_ID';
}
