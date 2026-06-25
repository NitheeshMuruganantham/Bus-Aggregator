class MakeMyTripService {
  static const String affiliateId = 'YOUR_MMT_AFFILIATE_ID_HERE';

  static String getBusDeepLink({
    required String from,
    required String to,
    required String date,
  }) {
    final formattedDate = date.replaceAll('/', '-');
    return 'https://www.makemytrip.com'
        '/bus-tickets/$from-to-$to.html'
        '?aff=$affiliateId&dt=$formattedDate';
  }
}
